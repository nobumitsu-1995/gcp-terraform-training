const express = require("express");
const app = express();

// Cloud Run が設定する環境変数 PORT でリッスンする
const PORT = process.env.PORT || 8080;

// アプリ名（Dockerfile の ENV で設定する値）
const APP_NAME = process.env.APP_NAME || "hello-app";

app.get("/", (req, res) => {
  res.json({
    message: "Hello from Cloud Run!",
    app: APP_NAME,
    revision: process.env.K_REVISION || "unknown", // Cloud Runが自動的に設定するリビジョン名
  });
});

app.get("/health", (req, res) => {
  res.json({ status: "ok" });
});

app.listen(PORT, "0.0.0.0", () => {
  console.log(`${APP_NAME} listening on port ${PORT}`);
});
