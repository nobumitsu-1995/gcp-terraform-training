// notify-svc/index.js
// SQS(processed) をトリガーに、通知ログを出力する
// 本番では SES / SNS(SMS) / Slack Webhook 等に送信する想定だが、研修ではログ出力のみ
exports.handler = async (event) => {
  for (const record of event.Records) {
    const order = JSON.parse(JSON.parse(record.body).Message);

    // 本番では: ses.sendEmail({ ... }) など
    console.log(
      `[NOTIFY] Order ${order.order_id} processed. ` +
        `Customer: ${order.customer}, Amount: ${order.amount}`
    );
  }

  return { statusCode: 200 };
};
