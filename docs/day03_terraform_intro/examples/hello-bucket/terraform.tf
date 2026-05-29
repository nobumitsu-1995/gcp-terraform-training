terraform {
  required_version = ">= 1.5" # Terraform本体のバージョン制約

  required_providers {
    google = {
      source  = "hashicorp/google" # GCP用の公式プロバイダ
      version = "~> 5.0"           # メジャーバージョン5系に固定
    }
  }
}

provider "google" {
  project = var.project_id # 操作対象のGCPプロジェクト
  region  = var.region     # デフォルトのリージョン
}
