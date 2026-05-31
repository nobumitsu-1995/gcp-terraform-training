data "archive_file" "processing_svc" {
  type        = "zip"
  source_dir  = "${path.module}/../processing-svc"
  output_path = "${path.module}/processing-svc.zip"
}

resource "aws_lambda_function" "processing" {
  function_name = "level3-processing-svc"
  runtime       = "nodejs20.x"
  handler       = "index.handler"
  role          = aws_iam_role.processing.arn
  timeout       = 60
  memory_size   = 256

  filename         = data.archive_file.processing_svc.output_path
  source_code_hash = data.archive_file.processing_svc.output_base64sha256

  environment {
    variables = {
      PROCESSED_BUCKET = aws_s3_bucket.processed.bucket
      PROCESSED_TOPIC  = aws_sns_topic.processed.arn
    }
  }
}
