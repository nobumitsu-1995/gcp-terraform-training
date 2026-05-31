# process-order のソースを zip 化
data "archive_file" "processor" {
  type        = "zip"
  source_dir  = "${path.module}/../processor"
  output_path = "${path.module}/processor.zip"
}

# イベント処理関数 (Lambda)
resource "aws_lambda_function" "processor" {
  function_name = "process-order"
  runtime       = "nodejs20.x"
  handler       = "index.handler"
  role          = aws_iam_role.processor.arn
  timeout       = 60
  memory_size   = 256

  filename         = data.archive_file.processor.output_path
  source_code_hash = data.archive_file.processor.output_base64sha256

  environment {
    variables = {
      DATA_BUCKET = aws_s3_bucket.data.bucket
      RAW_BUCKET  = aws_s3_bucket.raw_events.bucket
    }
  }
}
