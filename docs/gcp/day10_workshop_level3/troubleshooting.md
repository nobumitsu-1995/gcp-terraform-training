# Day 10 トラブルシューティング集

研修全体で発生しがちな問題と対処法をまとめます。

---

## Terraform 関連

### `terraform apply` がタイムアウトする

Cloud SQL の作成には10〜15分かかることがあります。タイムアウト時間を延ばしてください:

```hcl
resource "google_sql_database_instance" "main" {
  # ...
  timeouts {
    create = "30m"
  }
}
```

### `terraform destroy` が失敗する

- Cloud SQL の `deletion_protection = false` を確認
- BigQuery テーブルの `deletion_protection = false` を確認
- GCS バケットの `force_destroy = true` を確認
- Cloud SQL のバックアップ・リードレプリカが残っていないか確認

### state lock が解除されない

別の人（または別ターミナル）が apply 中です。完了を待つか、緊急時は:

```bash
terraform force-unlock LOCK_ID
```

---

## API Gateway 関連

### `google-beta provider required` エラー

API Gateway の Terraform リソースには `provider = google-beta` の指定が必要です。

```hcl
terraform {
  required_providers {
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

resource "google_api_gateway_api" "quickbite" {
  provider = google-beta   # ← 必須
  api_id   = "quickbite-api"
}
```

### API Config の更新が反映されない

`google_api_gateway_api_config` は不変リソースです。OpenAPI spec を変えても既存のConfigは更新されず、新規Configが必要です。

```hcl
resource "google_api_gateway_api_config" "quickbite" {
  api                  = google_api_gateway_api.quickbite.api_id
  api_config_id_prefix = "quickbite-config-"   # ← prefix で自動連番

  lifecycle {
    create_before_destroy = true   # ← 必須。古いConfigを使ったままGatewayを更新
  }
}
```

### API Gateway のデプロイに時間がかかる

API Config の作成には数分かかることがあります。`lifecycle { create_before_destroy = true }` を設定しておくと、OpenAPI spec の変更時にダウンタイムなく更新できます。

---

## Cloud Run 関連

### Cloud Run で「Permission denied」

サービスアカウントに必要なロールが付与されていない可能性があります:

```bash
gcloud projects get-iam-policy $GOOGLE_CLOUD_PROJECT --format=json \
  | jq '.bindings[] | select(.members[] | contains("SA_EMAIL"))'
```

### Cloud Run のリビジョンが Ready にならない

- コンテナが `PORT` 環境変数で listen しているか確認
- イメージが `linux/amd64` でビルドされているか確認（Apple Silicon の場合 `--platform linux/amd64` が必要）
- メモリ不足の可能性。`--memory 512Mi` に上げてみる

### Pub/Sub Push が Cloud Run に届かない

- `pubsub-invoker-sa` に `roles/run.invoker` が付与されているか
- Cloud Run が「未認証アクセスを拒否」設定の場合、Pub/Sub の OIDC トークン認証用に SA を許可する
- Push subscription の `push_endpoint` URL が正しいか（パスまで含めて）

---

## Cloud SQL 関連

### Cloud SQL に接続できない（Cloud Run から）

Cloud Run からプライベートIPの Cloud SQL に接続するにはサーバーレスVPCコネクタが必要です:

```hcl
resource "google_cloud_run_v2_service" "order_svc" {
  template {
    vpc_access {
      connector = google_vpc_access_connector.main.id
      egress    = "PRIVATE_RANGES_ONLY"
    }
    # ...
  }
}
```

### Cloud SQL のテーブルが見つからない

Terraform で作るのは「Cloud SQL インスタンス」と「データベース」までです。**テーブル作成は別途必要** です。

```bash
# Cloud SQL Auth Proxy 経由で接続してテーブル作成
./cloud-sql-proxy PROJECT:REGION:INSTANCE_NAME &

psql "host=127.0.0.1 port=5432 user=appuser dbname=appdb" <<SQL
CREATE TABLE IF NOT EXISTS orders (
  order_id   TEXT PRIMARY KEY,
  customer   TEXT NOT NULL,
  product    TEXT,
  amount     NUMERIC NOT NULL,
  status     TEXT,
  created_at TIMESTAMPTZ NOT NULL
);
SQL
```

---

## 認証関連

### gcloud の認証情報が切れた

```bash
gcloud auth login
gcloud auth application-default login
gcloud config configurations list   # アクティブな設定の確認
```

### Docker push で `denied: permission_denied`

```bash
gcloud auth configure-docker asia-northeast1-docker.pkg.dev
```

を実行し直してください。

### Apple Silicon Mac で Docker push したイメージが Cloud Run で動かない

Apple Silicon (M1/M2/M3) は arm64 アーキテクチャです。Cloud Run は amd64 を使うため、明示的に指定が必要:

```bash
docker buildx build --platform linux/amd64 -t IMAGE_URL .
```

---

## 参考リンク

- Terraform Google Provider: https://registry.terraform.io/providers/hashicorp/google/latest/docs
- Terraform Google-Beta Provider: https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs
- GCP Always Free 枠: https://cloud.google.com/free/docs/free-cloud-features
- Cloud Run: https://cloud.google.com/run/docs
- Pub/Sub: https://cloud.google.com/pubsub/docs
- BigQuery: https://cloud.google.com/bigquery/docs
- Cloud SQL: https://cloud.google.com/sql/docs
- API Gateway: https://cloud.google.com/api-gateway/docs
- Terraform ベストプラクティス: https://cloud.google.com/docs/terraform/best-practices-for-terraform
