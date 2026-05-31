const { S3Client, PutObjectCommand } = require("@aws-sdk/client-s3");

const s3 = new S3Client({});
const DATA_BUCKET = process.env.DATA_BUCKET;
const RAW_BUCKET = process.env.RAW_BUCKET;

// SQS トリガーのハンドラ（SNS → SQS でメッセージが届く）
exports.handler = async (event) => {
  for (const record of event.Records) {
    // SQS の body は SNS 通知。元のペイロードは Message に入っている
    const notification = JSON.parse(record.body);
    const order = JSON.parse(notification.Message);

    console.log(`Processing order ${order.order_id}`);

    // 生イベントをアーカイブ
    await s3.send(
      new PutObjectCommand({
        Bucket: RAW_BUCKET,
        Key: `raw/${order.order_id}.json`,
        Body: notification.Message,
        ContentType: "application/json",
      })
    );

    // Athena 用に整形して保存（1注文1オブジェクト）
    const row = {
      order_id: order.order_id,
      customer: order.customer || null,
      amount: order.amount,
      items: order.items ? JSON.stringify(order.items) : null,
      created_at: new Date().toISOString(),
    };
    await s3.send(
      new PutObjectCommand({
        Bucket: DATA_BUCKET,
        Key: `orders/${order.order_id}.json`,
        Body: JSON.stringify(row),
        ContentType: "application/json",
      })
    );

    console.log(`Stored order ${order.order_id}`);
  }

  return { statusCode: 200 };
};
