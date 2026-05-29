output "db_instance" {
  value       = google_sql_database_instance.main.name
  description = "Cloud SQL インスタンス名"
}

output "db_private_ip" {
  value       = google_sql_database_instance.main.private_ip_address
  description = "Cloud SQL のプライベートIP（VPCコネクタ経由で接続する）"
}

output "vpc_name" {
  value       = google_compute_network.main.name
  description = "作成された VPC 名"
}

output "secret_name" {
  value       = google_secret_manager_secret.db_password.secret_id
  description = "Secret Manager 上のパスワードシークレット名"
}
