# 店舗から送られてくるCSVファイルの受け口
resource "google_storage_bucket" "raw_data" {
  name                        = "${var.project_id}-raw-csv"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true
}

# Cloud Functions のソースコードZIPを配置するバケット
resource "google_storage_bucket" "functions_source" {
  name                        = "${var.project_id}-functions-src"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true
}
