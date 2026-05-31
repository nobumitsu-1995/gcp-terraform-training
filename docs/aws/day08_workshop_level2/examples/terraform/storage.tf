# Athena 用データバケット
resource "aws_s3_bucket" "data" {
  bucket        = "${data.aws_caller_identity.current.account_id}-level2-data"
  force_destroy = true
}

# 生イベントのアーカイブ用バケット
resource "aws_s3_bucket" "raw_events" {
  bucket        = "${data.aws_caller_identity.current.account_id}-level2-raw-events"
  force_destroy = true
}

resource "aws_s3_bucket_lifecycle_configuration" "raw_events" {
  bucket = aws_s3_bucket.raw_events.id

  rule {
    id     = "expire-90d"
    status = "Enabled"

    expiration {
      days = 90
    }
  }
}
