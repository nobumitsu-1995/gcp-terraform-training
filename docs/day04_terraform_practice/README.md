# Day 4: Terraform実践パターン

**ゴール**: 変数管理、モジュール化、Remote State など実務パターンを習得する。

---

## 学習トピック

- `terraform.tfvars` と環境別変数ファイル（dev.tfvars / prod.tfvars）
- `count` と `for_each` による繰り返し
- モジュール化: 再利用可能なコードの分離
- Remote State Backend（GCSバックエンド）
- `terraform fmt` / `validate` によるコード品質管理

---

## 1. 推奨ディレクトリ構成

```
project/
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tf              # required_version, required_providers, backend
├── terraform.tfvars          # デフォルトの変数値（.gitignoreに入れる）
├── dev.tfvars                # 開発環境用の変数値
├── prod.tfvars               # 本番環境用の変数値
└── modules/
    └── gcs_bucket/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

完全なサンプルは [examples/multi-bucket/](./examples/multi-bucket/) を参照。

---

## 2. tfvars による環境切り替え

```bash
# デフォルト（terraform.tfvarsが自動読み込みされる）
terraform plan

# 環境を明示的に指定
terraform plan -var-file="dev.tfvars"
terraform plan -var-file="prod.tfvars"
```

> 💡 `.tfvars` ファイルに機密情報やプロジェクトIDを書く場合は、`.gitignore` に追加して Git にコミットしないこと。

---

## 3. モジュール化

「同じパターンを複数箇所で使う」場合はモジュールに切り出します。`modules/gcs_bucket/` ディレクトリを作成し、その中に `main.tf` / `variables.tf` / `outputs.tf` を置きます。

### モジュール定義例

```hcl
# modules/gcs_bucket/main.tf
resource "google_storage_bucket" "this" {
  name     = var.bucket_name
  location = var.location

  versioning {
    enabled = var.versioning_enabled
  }

  lifecycle_rule {
    condition { age = var.lifecycle_age_days }
    action    { type = "Delete" }
  }

  uniform_bucket_level_access = true
  force_destroy               = true
}
```

### 呼び出し側

```hcl
module "data_bucket" {
  source             = "./modules/gcs_bucket"
  bucket_name        = "${var.project_id}-data"
  location           = var.region
  versioning_enabled = true
  lifecycle_age_days = 90
}

module "logs_bucket" {
  source             = "./modules/gcs_bucket"
  bucket_name        = "${var.project_id}-logs"
  location           = var.region
  versioning_enabled = false
  lifecycle_age_days = 30
}
```

同じ構造のリソースを「変数だけ変えて何個も作る」ときに、コードの重複を排除できます。

---

## 4. Remote State Backend

State をローカルファイルではなくGCSに置く設定です。チーム開発では必須。

```bash
# 先にバケットをgcloudで作成しておく
gsutil mb -l asia-northeast1 gs://YOUR_PROJECT_ID-tfstate/
```

```hcl
# terraform.tf
terraform {
  backend "gcs" {
    bucket = "YOUR_PROJECT_ID-tfstate"   # stateファイルを保存するGCSバケット
    prefix = "terraform/state"           # バケット内のパス（環境ごとに分けると便利）
  }
}
```

> 💡 backend 設定を変更したら `terraform init -migrate-state` を実行して既存stateを移行する。

---

## 5. count と for_each

```hcl
# count: 同じ設定を N 個作る
resource "google_storage_bucket" "logs" {
  count    = 3
  name     = "logs-${count.index}"   # logs-0, logs-1, logs-2
  location = var.region
}

# for_each: 名前付きで複数作る（推奨）
resource "google_storage_bucket" "envs" {
  for_each = toset(["dev", "stg", "prd"])
  name     = "${var.project_id}-${each.key}"  # 各環境名でバケットを作る
  location = var.region
}
```

**`count` より `for_each` を推奨**: 要素の途中追加・削除でリソースが「ズレて」再作成される事故を防げます。

---

## 確認課題

モジュールで2つのGCSバケット（`data`, `logs`）を作成し、`terraform output` で両方のバケット名を表示できること。

---

## 補足

- 実務で役立つ Terraform Tips: [supplementary.md](./supplementary.md)

---

## 次のステップ

→ [Day 5: Level 1 ワークショップ — GCS静的サイト + LB + CDN](../day05_workshop_level1/README.md)
