output "topic_arn" {
  value       = aws_sns_topic.events.arn
  description = "SNS topic ARN"
}

output "queue_url" {
  value       = aws_sqs_queue.events.id
  description = "SQS queue URL"
}

output "data_bucket" {
  value       = aws_s3_bucket.data.bucket
  description = "S3 bucket for Athena source data"
}
