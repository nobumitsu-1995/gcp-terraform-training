// order-svc/index.js
// API Gateway (HTTP API) から呼ばれ、注文を RDS に保存して SNS に publish する
const { Pool } = require("pg");
const { SNSClient, PublishCommand } = require("@aws-sdk/client-sns");
const {
  SecretsManagerClient,
  GetSecretValueCommand,
} = require("@aws-sdk/client-secrets-manager");

const sns = new SNSClient({});
const secrets = new SecretsManagerClient({});
const TOPIC_ARN = process.env.TOPIC_ARN;

// 接続プールはコールドスタート間で使い回す
let pool;
async function getPool() {
  if (pool) return pool;
  const secret = await secrets.send(
    new GetSecretValueCommand({ SecretId: process.env.SECRET_ARN })
  );
  pool = new Pool({
    host: process.env.DB_HOST,
    database: process.env.DB_NAME,
    user: process.env.DB_USER,
    password: secret.SecretString,
    port: 5432,
    max: 1,
  });
  return pool;
}

exports.handler = async (event) => {
  const method = event.requestContext?.http?.method;
  const path = event.requestContext?.http?.path || event.rawPath || "";

  // ヘルスチェック
  if (method === "GET" && path.endsWith("/health")) {
    return json(200, { status: "ok" });
  }

  // 注文一覧
  if (method === "GET" && path.endsWith("/orders")) {
    try {
      const db = await getPool();
      const result = await db.query(
        "SELECT * FROM orders ORDER BY created_at DESC LIMIT 20"
      );
      return json(200, result.rows);
    } catch (err) {
      console.error("Failed to list orders:", err);
      return json(500, { error: "Internal server error" });
    }
  }

  // 注文受付
  if (method === "POST" && path.endsWith("/orders")) {
    let body;
    try {
      body = JSON.parse(event.body || "{}");
    } catch {
      return json(400, { error: "Invalid JSON" });
    }
    const { customer, product, amount } = body;
    if (!customer || !amount) {
      return json(400, { error: "customer and amount are required" });
    }

    const orderId = `ORD-${Date.now()}`;
    const createdAt = new Date().toISOString();

    try {
      // 1. RDS に保存
      const db = await getPool();
      await db.query(
        `INSERT INTO orders (order_id, customer, product, amount, status, created_at)
         VALUES ($1, $2, $3, $4, $5, $6)`,
        [orderId, customer, product || "unknown", amount, "received", createdAt]
      );

      // 2. SNS に publish（非同期で processing-svc に伝播）
      await sns.send(
        new PublishCommand({
          TopicArn: TOPIC_ARN,
          Message: JSON.stringify({
            order_id: orderId,
            customer,
            product,
            amount,
            status: "received",
            created_at: createdAt,
          }),
        })
      );

      console.log(`Order ${orderId} saved & published`);
      return json(202, { message: "Order accepted", order_id: orderId });
    } catch (err) {
      console.error("Failed to process order:", err);
      return json(500, { error: "Internal server error" });
    }
  }

  return json(404, { error: "Not Found" });
};

function json(statusCode, obj) {
  return {
    statusCode,
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(obj),
  };
}
