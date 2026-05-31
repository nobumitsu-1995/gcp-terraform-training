data "archive_file" "notify_svc" {
  type        = "zip"
  source_dir  = "${path.module}/../notify-svc"
  output_path = "${path.module}/notify-svc.zip"
}

resource "aws_lambda_function" "notify" {
  function_name = "level3-notify-svc"
  runtime       = "nodejs20.x"
  handler       = "index.handler"
  role          = aws_iam_role.notify.arn
  timeout       = 30
  memory_size   = 128

  filename         = data.archive_file.notify_svc.output_path
  source_code_hash = data.archive_file.notify_svc.output_base64sha256
}
