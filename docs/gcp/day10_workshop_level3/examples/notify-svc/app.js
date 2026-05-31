// notify-svc/app.js
// Pub/Sub Push で processed トピックからメッセージを受け取り、通知ログを出力するサービス
// 本番ではSendGrid / SES / Slack Webhook 等に接続する想定だが、研修ではログ出力のみ
const express = require("express");

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 8080;

// POST / — Pub/Sub Push エンドポイント
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
    return res.status(200).send("Unparseable message ignored");
  }

  // 本番では: SendGrid.send({ to: order.customer_email, ... })
  console.log(
    `[NOTIFY] Order ${order.order_id} processed. ` +
      `Customer: ${order.customer}, Amount: ${order.amount}`,
  );

  res.status(204).send();
});

app.get("/health", (req, res) => res.json({ status: "ok" }));

app.listen(PORT, "0.0.0.0", () => {
  console.log(`Notify Service listening on port ${PORT}`);
});
