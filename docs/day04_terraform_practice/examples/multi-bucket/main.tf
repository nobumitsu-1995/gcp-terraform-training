# データ用バケット: バージョニング有効、90日で自動削除
module "data_bucket" {
  source             = "./modules/gcs_bucket"
  bucket_name        = "${var.project_id}-data"
  location           = var.region
  versioning_enabled = true
  lifecycle_age_days = 90
}

# ログ用バケット: バージョニング無効、30日で自動削除（コスト節約）
module "logs_bucket" {
  source             = "./modules/gcs_bucket"
  bucket_name        = "${var.project_id}-logs"
  location           = var.region
  versioning_enabled = false
  lifecycle_age_days = 30
}
