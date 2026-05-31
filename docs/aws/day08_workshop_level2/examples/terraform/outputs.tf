output "order_api_url" {
  value       = aws_lambda_function_url.order_api.function_url
  description = "注文受付APIのURL"
}

output "topic_arn" {
  value       = aws_sns_topic.orders.arn
  description = "SNSトピックARN"
}

output "data_bucket" {
  value       = aws_s3_bucket.data.bucket
  description = "Athena用データバケット"
}

output "athena_database" {
  value       = aws_glue_catalog_database.ecommerce.name
  description = "Glue/Athena データベース名"
}
