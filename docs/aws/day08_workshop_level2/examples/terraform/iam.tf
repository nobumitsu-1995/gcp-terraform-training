# Lambda の共通 assume role ポリシー
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
# order-api 用ロール
# ============================================================
resource "aws_iam_role" "order_api" {
  name               = "level2-order-api-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy_attachment" "order_api_basic" {
  role       = aws_iam_role.order_api.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# SNS への publish 権限のみ（最小権限）
resource "aws_iam_role_policy" "order_api_sns" {
  name = "publish-sns"
  role = aws_iam_role.order_api.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sns:Publish"
      Resource = aws_sns_topic.orders.arn
    }]
  })
}

# ============================================================
# process-order 用ロール
# ============================================================
resource "aws_iam_role" "processor" {
  name               = "level2-processor-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy_attachment" "processor_basic" {
  role       = aws_iam_role.processor.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# SQS をトリガーにするための権限
resource "aws_iam_role_policy_attachment" "processor_sqs" {
  role       = aws_iam_role.processor.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}

# S3 への書き込み権限のみ（最小権限）
resource "aws_iam_role_policy" "processor_s3" {
  name = "write-s3"
  role = aws_iam_role.processor.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["s3:PutObject"]
      Resource = [
        "${aws_s3_bucket.data.arn}/*",
        "${aws_s3_bucket.raw_events.arn}/*",
      ]
    }]
  })
}
