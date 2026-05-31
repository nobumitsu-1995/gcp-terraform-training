# ソースコードZIPをGCSにアップロード
#
# 事前に functions ディレクトリで以下を実行してZIPを作っておくこと:
#   cd ../functions && zip -r ../terraform/csv-trigger.zip . && cd -
resource "google_storage_bucket_object" "function_zip" {
  name   = "csv-trigger-v1.zip"
  bucket = google_storage_bucket.functions_source.name
  source = "${path.module}/csv-trigger.zip"
}

# Cloud Functions（第2世代）
resource "google_cloudfunctions2_function" "csv_trigger" {
  name     = "csv-trigger"
  location = var.region

  build_config {
    runtime     = "nodejs20"
    entry_point = "onCsvUpload" # エクスポートされた関数名

    source {
      storage_source {
        bucket = google_storage_bucket.functions_source.name
        object = google_storage_bucket_object.function_zip.name
      }
    }
  }

  service_config {
    max_instance_count    = 1     # 最大インスタンス数（コスト制御）
    available_memory      = "256M"
    timeout_seconds       = 60
    service_account_email = google_service_account.etl_worker.email

    environment_variables = {
      PUBSUB_TOPIC = google_pubsub_topic.csv_uploaded.id
    }
  }

  event_trigger {
    trigger_region = var.region
    event_type     = "google.cloud.storage.object.v1.finalized" # GCSオブジェクト作成完了イベント

    event_filters {
      attribute = "bucket"
      value     = google_storage_bucket.raw_data.name
    }
  }
}
