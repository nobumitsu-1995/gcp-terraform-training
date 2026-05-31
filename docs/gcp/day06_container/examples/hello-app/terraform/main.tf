terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type        = string
  description = "GCPプロジェクトID"
}

variable "region" {
  type    = string
  default = "asia-northeast1"
}

# コンテナイメージの保管場所
resource "google_artifact_registry_repository" "main" {
  location      = var.region      # リポジトリのリージョン
  repository_id = "training-repo" # リポジトリ名
  format        = "DOCKER"        # Docker形式
}

# Cloud Run サービス（AWSの ECS Fargate + ALB に近い概念）
resource "google_cloud_run_v2_service" "hello" {
  name     = "hello-app"
  location = var.region

  template {
    containers {
      # Artifact Registry のイメージを指定
      image = "asia-northeast1-docker.pkg.dev/${var.project_id}/training-repo/hello-app:v1"

      ports {
        container_port = 8080 # コンテナが待ち受けるポート
      }

      resources {
        limits = {
          cpu    = "1"     # vCPU数の上限
          memory = "256Mi" # メモリの上限
        }
      }

      # Dockerfile の ENV を上書きしたい場合はここで指定
      env {
        name  = "APP_NAME"
        value = "hello-cloud-run"
      }
    }

    scaling {
      min_instance_count = 0 # リクエストがなければ0にスケールイン（コスト最適）
      max_instance_count = 2 # 最大2インスタンスまでスケールアウト
    }
  }
}

# 未認証アクセスを許可（テスト用。本番ではIAMで制御する）
resource "google_cloud_run_v2_service_iam_member" "public" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.hello.name
  role     = "roles/run.invoker" # Cloud Run を呼び出せるロール
  member   = "allUsers"          # 全ユーザーに許可
}

output "service_url" {
  value       = google_cloud_run_v2_service.hello.uri
  description = "Cloud RunサービスのHTTPSエンドポイント"
}
