const express = require("express");
const { Storage } = require("@google-cloud/storage");
const { BigQuery } = require("@google-cloud/bigquery");
const { parse } = require("csv-parse/sync");

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 8080;
const PROJECT = process.env.GCP_PROJECT;
const DATASET = process.env.BQ_DATASET;
const TABLE = process.env.BQ_TABLE;

const storage = new Storage({ projectId: PROJECT });
const bigquery = new BigQuery({ projectId: PROJECT });

// Pub/Sub Push subscription からのリクエストを受ける
//
// リクエストボディは以下の形式 (Pub/Sub push の仕様):
//   { "message": { "data": "<base64-encoded JSON>", ... }, "subscription": "..." }
//
// data を decode すると Cloud Functions が publish した { bucket, file } が得られる
app.post("/process", async (req, res) => {
  try {
    const pubsubMessage = req.body.message;
    if (!pubsubMessage || !pubsubMessage.data) {
      return res.status(400).send("no message");
    }

    const payload = JSON.parse(
      Buffer.from(pubsubMessage.data, "base64").toString("utf-8"),
    );
    const { bucket, file } = payload;
    console.log(`Processing gs://${bucket}/${file}`);

    // 1. GCS から CSV をダウンロード
    const [contents] = await storage.bucket(bucket).file(file).download();

    // 2. CSV をパース
    const records = parse(contents, {
      columns: true,
      skip_empty_lines: true,
      trim: true,
    });

    // 3. BigQuery にロード
    const rows = records.map((r) => ({
      order_id: r.order_id,
      customer: r.customer,
      product: r.product || null,
      amount: Number(r.amount),
      status: r.status || null,
      created_at: r.created_at,
    }));

    await bigquery.dataset(DATASET).table(TABLE).insert(rows);
    console.log(`Inserted ${rows.length} rows into ${DATASET}.${TABLE}`);

    res.status(200).send("ok");
  } catch (err) {
    console.error("ETL failed:", err);
    // 500 を返すと Pub/Sub が自動的にリトライしてくれる
    res.status(500).send("failed");
  }
});

app.get("/health", (req, res) => res.json({ status: "ok" }));

app.listen(PORT, "0.0.0.0", () => {
  console.log(`ETL Worker listening on port ${PORT}`);
});
