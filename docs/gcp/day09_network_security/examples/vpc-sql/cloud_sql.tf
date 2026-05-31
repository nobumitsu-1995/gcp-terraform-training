# Cloud SQL PostgreSQL（AWSでいう RDS）
resource "google_sql_database_instance" "main" {
  name             = "training-postgres"
  database_version = "POSTGRES_15"
  region           = var.region

  # VPCピアリング完了後に作成（必須）
  depends_on = [google_service_networking_connection.private_vpc]

  settings {
    tier              = "db-f1-micro" # 最小インスタンスタイプ（≈$0.015/時間）
    edition           = "ENTERPRISE"
    availability_type = "ZONAL" # シングルゾーン（HA不要=コスト節約）

    ip_configuration {
      ipv4_enabled    = false # パブリックIP無効（セキュリティ向上）
      private_network = google_compute_network.main.id
    }

    disk_size       = 10    # ディスク容量（GB）最小
    disk_autoresize = false # 自動拡張OFF（研修用コスト管理）
  }

  deletion_protection = false # terraform destroy を許可（研修用）
}

# データベースの作成
resource "google_sql_database" "app" {
  name     = "appdb"
  instance = google_sql_database_instance.main.name
}

# ランダムなパスワードを生成
resource "random_password" "db_password" {
  length  = 24
  special = true
}

# データベースユーザーの作成
resource "google_sql_user" "app" {
  name     = "appuser"
  instance = google_sql_database_instance.main.name
  password = random_password.db_password.result
}
