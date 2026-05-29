output "data_bucket" {
  value       = module.data_bucket.bucket_name
  description = "データ用バケット名"
}

output "logs_bucket" {
  value       = module.logs_bucket.bucket_name
  description = "ログ用バケット名"
}
