# Lambda 共通の assume role ポリシー
data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# ============================================================
# order-svc ロール
# ============================================================
resource "aws_iam_role" "order" {
  name               = "level3-order-svc-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

# VPC内Lambdaに必要（ENI作成 + 基本ログ）
resource "aws_iam_role_policy_attachment" "order_vpc" {
  role       = aws_iam_role.order.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy" "order_app" {
  name = "order-app"
  role = aws_iam_role.order.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "secretsmanager:GetSecretValue"
        Resource = aws_secretsmanager_secret.db_password.arn
      },
      {
        Effect   = "Allow"
        Action   = "sns:Publish"
        Resource = aws_sns_topic.orders.arn
      },
    ]
  })
}

# ============================================================
# processing-svc ロール
# ============================================================
resource "aws_iam_role" "processing" {
  name               = "level3-processing-svc-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy_attachment" "processing_basic" {
  role       = aws_iam_role.processing.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "processing_sqs" {
  role       = aws_iam_role.processing.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}

resource "aws_iam_role_policy" "processing_app" {
  name = "processing-app"
  role = aws_iam_role.processing.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.processed.arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = "sns:Publish"
        Resource = aws_sns_topic.processed.arn
      },
    ]
  })
}

# ============================================================
# notify-svc ロール
# ============================================================
resource "aws_iam_role" "notify" {
  name               = "level3-notify-svc-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy_attachment" "notify_basic" {
  role       = aws_iam_role.notify.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "notify_sqs" {
  role       = aws_iam_role.notify.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}
