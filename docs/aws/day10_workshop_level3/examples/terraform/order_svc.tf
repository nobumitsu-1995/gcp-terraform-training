# order-svc のソースを zip 化（事前に `npm install --omit=dev` が必要）
data "archive_file" "order_svc" {
  type        = "zip"
  source_dir  = "${path.module}/../order-svc"
  output_path = "${path.module}/order-svc.zip"
}

resource "aws_lambda_function" "order" {
  function_name = "level3-order-svc"
  runtime       = "nodejs20.x"
  handler       = "index.handler"
  role          = aws_iam_role.order.arn
  timeout       = 30
  memory_size   = 256

  filename         = data.archive_file.order_svc.output_path
  source_code_hash = data.archive_file.order_svc.output_base64sha256

  # RDS（プライベート）に接続するため VPC 内に配置
  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      DB_HOST    = aws_db_instance.main.address
      DB_NAME    = aws_db_instance.main.db_name
      DB_USER    = "appuser"
      SECRET_ARN = aws_secretsmanager_secret.db_password.arn
      TOPIC_ARN  = aws_sns_topic.orders.arn
    }
  }
}
