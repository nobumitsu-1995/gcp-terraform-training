# order-api のソースを zip 化
data "archive_file" "order_api" {
  type        = "zip"
  source_dir  = "${path.module}/../order-api"
  output_path = "${path.module}/order-api.zip"
}

# 注文受付 API (Lambda)
resource "aws_lambda_function" "order_api" {
  function_name = "order-api"
  runtime       = "nodejs20.x"
  handler       = "index.handler"
  role          = aws_iam_role.order_api.arn

  filename         = data.archive_file.order_api.output_path
  source_code_hash = data.archive_file.order_api.output_base64sha256

  environment {
    variables = {
      TOPIC_ARN = aws_sns_topic.orders.arn
    }
  }
}

# HTTPエンドポイント（API Gateway 不要）
resource "aws_lambda_function_url" "order_api" {
  function_name      = aws_lambda_function.order_api.function_name
  authorization_type = "NONE"
}
