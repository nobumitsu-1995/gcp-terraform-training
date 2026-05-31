# ============================================================
# GCP API Gateway（3層構造: API → API Config → Gateway）
#
# AWS API Gateway に相当するフルマネージドサービス。
# OpenAPI spec をアップロードするだけで、ルーティング・認証・
# レート制限付きのAPIエンドポイントが自動的にプロビジョニングされる。
# ============================================================

# API リソース: 論理的なAPIの入れ物
resource "google_api_gateway_api" "quickbite" {
  provider     = google-beta
  api_id       = "quickbite-api"
  display_name = "QuickBite Order API"

  depends_on = [
    google_project_service.apigateway,
    google_project_service.servicecontrol,
    google_project_service.servicemanagement,
  ]
}

# API Config: OpenAPI spec とバックエンド設定を紐付ける
resource "google_api_gateway_api_config" "quickbite" {
  provider             = google-beta
  api                  = google_api_gateway_api.quickbite.api_id
  api_config_id_prefix = "quickbite-config-"

  # OpenAPI spec をBase64エンコードして渡す
  openapi_documents {
    document {
      path = "openapi.yaml"
      contents = base64encode(templatefile("${path.module}/openapi.yaml", {
        # テンプレート変数でCloud RunのURLを動的に埋め込む
        order_svc_url = google_cloud_run_v2_service.order_svc.uri
      }))
    }
  }

  # API Gateway がバックエンドを呼び出す際に使うサービスアカウント
  gateway_config {
    backend_config {
      google_service_account = google_service_account.api_gateway.email
    }
  }

  # API Config は不変（immutable）。変更時は新しいConfigを先に作ってから古いのを削除する
  lifecycle {
    create_before_destroy = true
  }
}

# Gateway: 実際にトラフィックを受けるエンドポイント
resource "google_api_gateway_gateway" "quickbite" {
  provider   = google-beta
  gateway_id = "quickbite-gateway"
  region     = var.region

  api_config = google_api_gateway_api_config.quickbite.id

  depends_on = [google_api_gateway_api_config.quickbite]
}
