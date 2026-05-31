// processing-svc/app.js
// Pub/Sub Push でordersトピックからメッセージを受け取り、
// GCS への加工済みファイル書き込み + BigQuery へのロード + processedトピックへ通知
const express = require("express");
const { Storage } = require("@google-cloud/storage");
const { BigQuery } = require("@google-cloud/bigquery");
const { PubSub } = require("@google-cloud/pubsub");

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 8080;
const BUCKET = process.env.PROCESSED_BUCKET;
const DATASET = process.env.BQ_DATASET;
const TABLE = process.env.BQ_TABLE;
const PROCESSED_TOPIC = process.env.PROCESSED_TOPIC;

const storage = new Storage();
const bigquery = new BigQuery();
const pubsub = new PubSub({ projectId: process.env.GCP_PROJECT });

// POST / — Pub/Sub Push エンドポイント
// Pub/Sub からのメッセージは `{ message: { data: <base64-encoded> } }` の形式で届く
app.post("/", async (req, res) => {
  const pubsubMessage = req.body.message;
  if (!pubsubMessage || !pubsubMessage.data) {
    console.error("Invalid Pub/Sub message:", req.body);
    return res.status(400).send("Bad Request: no message data");
  }

  let order;
  try {
    const decoded = Buffer.from(pubsubMessage.data, "base64").toString("utf-8");
    order = JSON.parse(decoded);
  } catch (err) {
    console.error("Failed to parse message:", err);
    // 復旧不能なメッセージは ack（200を返す）してDLQに送らない
    return res.status(200).send("Unparseable message ignored");
  }

  console.log(`Processing order: ${order.order_id}`);

  try {
    // 1. GCS に加工済みJSONを保存
    const fileName = `orders/${order.order_id}.json`;
    await storage.bucket(BUCKET).file(fileName).save(JSON.stringify(order), {
      contentType: "application/json",
    });
    console.log(`  -> Saved to gs://${BUCKET}/${fileName}`);

    // 2. BigQuery にロード（ストリーミング挿入）
    await bigquery
      .dataset(DATASET)
      .table(TABLE)
      .insert([
        {
          order_id: order.order_id,
          customer: order.customer,
          product: order.product || null,
          amount: order.amount,
          status: "processed",
          created_at: order.created_at,
        },
      ]);
    console.log(`  -> Inserted into BigQuery ${DATASET}.${TABLE}`);

    // 3. processed トピックに publish（Notify Svc へ伝播）
    const processed = { ...order, status: "processed", processed_at: new Date().toISOString() };
    await pubsub
      .topic(PROCESSED_TOPIC)
      .publishMessage({ data: Buffer.from(JSON.stringify(processed)) });
    console.log(`  -> Published to ${PROCESSED_TOPIC}`);

    res.status(204).send();
  } catch (err) {
    console.error("Failed to process order:", err);
    // 5xx を返すと Pub/Sub が自動でリトライする
    res.status(500).send("Internal Server Error");
  }
});

app.get("/health", (req, res) => res.json({ status: "ok" }));

app.listen(PORT, "0.0.0.0", () => {
  console.log(`Processing Service listening on port ${PORT}`);
});
