output "api_url" {
  value       = aws_apigatewayv2_api.main.api_endpoint
  description = "API Gateway のベースURL（/orders にPOSTする）"
}

output "db_endpoint" {
  value       = aws_db_instance.main.address
  description = "RDS のエンドポイント（VPC内からのみ到達可能）"
}

output "processed_bucket" {
  value       = aws_s3_bucket.processed.bucket
  description = "加工済みデータの S3 バケット"
}

output "athena_database" {
  value       = aws_glue_catalog_database.analytics.name
  description = "Athena/Glue データベース名"
}
