// processing-svc/index.js
// SQS(orders) をトリガーに、S3へ加工済みデータを保存し SNS(processed) へ publish する
const { S3Client, PutObjectCommand } = require("@aws-sdk/client-s3");
const { SNSClient, PublishCommand } = require("@aws-sdk/client-sns");

const s3 = new S3Client({});
const sns = new SNSClient({});
const BUCKET = process.env.PROCESSED_BUCKET;
const PROCESSED_TOPIC = process.env.PROCESSED_TOPIC;

exports.handler = async (event) => {
  for (const record of event.Records) {
    // SQS の body は SNS 通知。元データは Message に入っている
    const order = JSON.parse(JSON.parse(record.body).Message);
    console.log(`Processing order: ${order.order_id}`);

    // 1. S3 に加工済みJSONを保存（Athena 分析対象）
    await s3.send(
      new PutObjectCommand({
        Bucket: BUCKET,
        Key: `orders/${order.order_id}.json`,
        Body: JSON.stringify({
          order_id: order.order_id,
          customer: order.customer,
          product: order.product || null,
          amount: order.amount,
          status: "processed",
          created_at: order.created_at,
        }),
        ContentType: "application/json",
      })
    );

    // 2. processed トピックに publish（notify-svc へ伝播）
    await sns.send(
      new PublishCommand({
        TopicArn: PROCESSED_TOPIC,
        Message: JSON.stringify({
          ...order,
          status: "processed",
          processed_at: new Date().toISOString(),
        }),
      })
    );

    console.log(`Processed & published order ${order.order_id}`);
  }

  return { statusCode: 200 };
};
