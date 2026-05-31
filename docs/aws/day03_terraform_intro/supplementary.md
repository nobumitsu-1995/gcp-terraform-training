# Day 3 補足: Terraform チートシート

## コマンド

```bash
terraform init                  # 初期化
terraform fmt                   # コードフォーマット
terraform validate              # 構文チェック
terraform plan                  # 差分プレビュー
terraform apply                 # 適用
terraform apply -auto-approve   # 確認なしで適用
terraform destroy               # 削除
terraform show                  # state の内容表示
terraform state list            # 管理リソース一覧
```

## HCLの構成要素

```hcl
# 変数
variable "region" {
  type        = string
  description = "AWS region"
  default     = "ap-northeast-1"
}

# ローカル値
locals {
  bucket_prefix = "training"
}

# データソース（既存情報の参照。ここではアカウントID）
data "aws_caller_identity" "current" {}

# リソース
resource "aws_s3_bucket" "this" {
  bucket = "${local.bucket_prefix}-${data.aws_caller_identity.current.account_id}"
}

# 出力
output "bucket_name" {
  value = aws_s3_bucket.this.bucket
}
```

## 変数の渡し方

```bash
terraform apply -var="region=us-east-1"           # コマンドライン
terraform apply -var-file="dev.tfvars"            # ファイル
export TF_VAR_region=us-east-1                      # 環境変数
```

## state 操作

```bash
terraform state list              # リソース一覧
terraform state show RESOURCE     # 詳細表示
terraform state rm RESOURCE       # state から除外（リソースは残る）
terraform import RESOURCE ID      # 既存リソースをstateに取り込む
```

## トラブルシューティング

```
Error: creating S3 Bucket: AccessDenied: ... not authorized to perform: s3:CreateBucket
→ IAM権限を確認。s3:CreateBucket 等を許可するポリシーが必要。

Error: creating S3 Bucket: BucketAlreadyExists
→ バケット名はグローバルで一意。アカウントIDやランダム接尾辞で重複を避ける。
```

（以下略）
