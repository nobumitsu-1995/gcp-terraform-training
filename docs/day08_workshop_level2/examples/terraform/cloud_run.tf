resource "google_cloud_run_v2_service" "etl_worker" {
  name     = "etl-worker"
  location = var.region

  template {
    service_account = google_service_account.etl_worker.email

    containers {
      image = "asia-northeast1-docker.pkg.dev/${var.project_id}/training-repo/etl-worker:v1"

      ports {
        container_port = 8080
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }

      env { name = "BQ_DATASET", value = google_bigquery_dataset.pipeline.dataset_id }
      env { name = "BQ_TABLE", value = google_bigquery_table.orders.table_id }
      env { name = "GCP_PROJECT", value = var.project_id }
    }

    scaling {
      min_instance_count = 0
      max_instance_count = 2
    }
  }
}
