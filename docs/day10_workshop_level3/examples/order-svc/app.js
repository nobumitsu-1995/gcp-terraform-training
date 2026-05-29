// order-svc/app.js
// 注文を受け付けてCloud SQLに保存し、Pub/Subにpublishするサービス
const express = require("express");
const { PubSub } = require("@google-cloud/pubsub");
const { Pool } = require("pg");

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 8080;
const TOPIC = process.env.PUBSUB_TOPIC;

// Cloud SQL (PostgreSQL) への接続プール
// DB_HOST はプライベートIP（VPCコネクタ経由で接続）
const pool = new Pool({
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  port: 5432,
});

const pubsub = new PubSub({ projectId: process.env.GCP_PROJECT });

// POST /orders — 注文を受け付けてDB保存 + Pub/Sub publish
app.post("/orders", async (req, res) => {
  const { customer, product, amount } = req.body;

  if (!customer || !amount) {
    return res.status(400).json({ error: "customer and amount are required" });
  }

  const orderId = `ORD-${Date.now()}`;
  const createdAt = new Date().toISOString();

  try {
    // 1. Cloud SQL に保存
    await pool.query(
      `INSERT INTO orders (order_id, customer, product, amount, status, created_at)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [orderId, customer, product || "unknown", amount, "received", createdAt],
    );

    // 2. Pub/Sub に publish（非同期で Processing Svc に伝播）
    const order = {
      order_id: orderId,
      customer,
      product,
      amount,
      status: "received",
      created_at: createdAt,
    };
    const messageId = await pubsub
      .topic(TOPIC)
      .publishMessage({ data: Buffer.from(JSON.stringify(order)) });

    console.log(`Order ${orderId} saved & published (msg: ${messageId})`);

    res.status(202).json({
      message: "Order accepted",
      order_id: orderId,
    });
  } catch (err) {
    console.error("Failed to process order:", err);
    res.status(500).json({ error: "Internal server error" });
  }
});

// GET /orders — 注文一覧
app.get("/orders", async (req, res) => {
  const limit = parseInt(req.query.limit) || 20;
  try {
    const result = await pool.query(
      "SELECT * FROM orders ORDER BY created_at DESC LIMIT $1",
      [limit],
    );
    res.json(result.rows);
  } catch (err) {
    console.error("Failed to list orders:", err);
    res.status(500).json({ error: "Internal server error" });
  }
});

// GET /health — ヘルスチェック（API Gatewayから疎通確認に使う）
app.get("/health", (req, res) => res.json({ status: "ok" }));

app.listen(PORT, "0.0.0.0", () => {
  console.log(`Order Service listening on port ${PORT}`);
});
