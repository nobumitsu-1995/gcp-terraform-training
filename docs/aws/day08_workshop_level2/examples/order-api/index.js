const { SNSClient, PublishCommand } = require("@aws-sdk/client-sns");

const sns = new SNSClient({});
const TOPIC_ARN = process.env.TOPIC_ARN;

// Lambda Function URL のHTTPハンドラ
exports.handler = async (event) => {
  try {
    const order = JSON.parse(event.body || "{}");

    // 簡単なバリデーション
    if (!order.order_id || !order.amount) {
      return {
        statusCode: 400,
        body: JSON.stringify({ error: "order_id and amount are required" }),
      };
    }

    // SNS にメッセージを publish
    const out = await sns.send(
      new PublishCommand({
        TopicArn: TOPIC_ARN,
        Message: JSON.stringify(order),
      })
    );

    console.log(`Published ${out.MessageId} for order ${order.order_id}`);
    return {
      statusCode: 202,
      body: JSON.stringify({ message: "Order accepted", messageId: out.MessageId }),
    };
  } catch (err) {
    console.error("Error publishing message:", err);
    return { statusCode: 500, body: JSON.stringify({ error: "Internal server error" }) };
  }
};
