# --- Order Svc: 注文受付 → Cloud SQL保存 + Pub/Sub publish ---
resource "google_cloud_run_v2_service" "order_svc" {
  name     = "order-svc"
  location = var.region

  template {
    service_account = google_service_account.order_svc.email

    # VPCコネクタ経由でCloud SQLのプライベートIPに接続
    vpc_access {
      connector = google_vpc_access_connector.main.id
      egress    = "PRIVATE_RANGES_ONLY"
    }

    containers {
      image = "asia-northeast1-docker.pkg.dev/${var.project_id}/training-repo/order-svc:v1"
      ports { container_port = 8080 }

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }

      env { name = "DB_HOST", value = google_sql_database_instance.main.private_ip_address }
      env { name = "DB_NAME", value = google_sql_database.app.name }
      env { name = "DB_USER", value = google_sql_user.app.name }
      env { name = "PUBSUB_TOPIC", value = google_pubsub_topic.orders.id }
      env { name = "GCP_PROJECT", value = var.project_id }

      # パスワードはSecret Managerから取得（環境変数に平文で書かない）
      env {
        name = "DB_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.db_password.secret_id
            version = "latest"
          }
        }
      }
    }

    scaling {
      min_instance_count = 0
      max_instance_count = 2
    }
  }
}

# --- Processing Svc: データ加工 → GCS + BigQuery + processed topic publish ---
resource "google_cloud_run_v2_service" "processing_svc" {
  name     = "processing-svc"
  location = var.region

  template {
    service_account = google_service_account.processing_svc.email

    containers {
      image = "asia-northeast1-docker.pkg.dev/${var.project_id}/training-repo/processing-svc:v1"
      ports { container_port = 8080 }

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }

      env { name = "GCS_BUCKET", value = google_storage_bucket.processed.name }
      env { name = "BQ_DATASET", value = google_bigquery_dataset.analytics.dataset_id }
      env { name = "PUBSUB_PROCESSED_TOPIC", value = google_pubsub_topic.processed.id }
      env { name = "GCP_PROJECT", value = var.project_id }
    }

    scaling {
      min_instance_count = 0
      max_instance_count = 2
    }
  }
}

# --- Notify Svc: 通知ログ出力 ---
resource "google_cloud_run_v2_service" "notify_svc" {
  name     = "notify-svc"
  location = var.region

  template {
    service_account = google_service_account.notify_svc.email

    containers {
      image = "asia-northeast1-docker.pkg.dev/${var.project_id}/training-repo/notify-svc:v1"
      ports { container_port = 8080 }

      resources {
        limits = {
          cpu    = "1"
          memory = "256Mi"
        }
      }
    }

    scaling {
      min_instance_count = 0
      max_instance_count = 1
    }
  }
}
