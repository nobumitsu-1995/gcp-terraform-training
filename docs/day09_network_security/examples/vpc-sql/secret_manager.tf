# Secret Manager にパスワードを保存（平文でtfstateに残さない運用のため）
resource "google_secret_manager_secret" "db_password" {
  secret_id = "db-password"
  replication { auto {} } # 自動レプリケーション
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db_password.result
}
