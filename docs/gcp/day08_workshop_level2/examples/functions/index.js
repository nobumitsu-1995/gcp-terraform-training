const { PubSub } = require("@google-cloud/pubsub");

const pubsub = new PubSub();

/**
 * GCSにCSVがアップロードされたらPub/Subにpublishする
 * Cloud Functions (Gen2) のCloudEvent形式ハンドラー
 */
exports.onCsvUpload = async (cloudEvent) => {
  const data = cloudEvent.data;
  const bucket = data.bucket;
  const name = data.name;

  // CSV以外のファイルは無視する
  if (!name.endsWith(".csv")) {
    console.log(`Skipping non-CSV file: ${name}`);
    return;
  }

  const topicName = process.env.PUBSUB_TOPIC;
  const message = JSON.stringify({ bucket, file: name });

  const messageId = await pubsub.topic(topicName).publishMessage({
    data: Buffer.from(message),
  });

  console.log(`Published message ${messageId} for ${name}`);
};
