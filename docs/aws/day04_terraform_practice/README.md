# Day 4: Terraform実践（モジュール・変数・backend）

**ゴール**: 再利用可能なモジュールを作り、リモートstateを使えるようになる。

---

## 1. 変数と tfvars

環境ごとに異なる値（リージョン、環境名、リソース数）は変数化し、`.tfvars` ファイルで切り替えます。

```hcl
# variables.tf
variable "region" {
  type    = string
  default = "ap-northeast-1"
}

variable "environment" {
  type    = string
  default = "dev"
}
```

```bash
terraform apply -var-file="dev.tfvars"
```

---

## 2. モジュール化

繰り返し使う構成は **モジュール** に切り出します。

```
multi-bucket/
├── main.tf           # モジュールを呼び出す
├── variables.tf
├── outputs.tf
├── terraform.tf
├── dev.tfvars
└── modules/
    └── s3_bucket/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

使用するコード: [examples/multi-bucket/](./examples/multi-bucket/)

---

## 3. backend（リモートstate）

state をローカルではなく S3 に保存することで、チームで共有できます。ロック（同時applyの防止）には DynamoDB テーブルを併用するのが定番です。

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "multi-bucket/terraform.tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

```bash
# backend用のバケットとロックテーブルは事前に作成しておく
aws s3 mb s3://my-terraform-state-bucket --region ap-northeast-1
aws s3api put-bucket-versioning \
  --bucket my-terraform-state-bucket \
  --versioning-configuration Status=Enabled

aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ap-northeast-1

# backend を指定して初期化
terraform init
```

⚠️ backend バケットとロックテーブルは Terraform 管理外で先に作る（鶏卵問題を避けるため）。

> 💡 GCPの `backend "gcs"` はバケット自身がロックを行いますが、AWSの `backend "s3"` は伝統的に **DynamoDB テーブルでロック** します（S3ネイティブロックも利用可）。

---

## 4. ハンズオン

```bash
cd examples/multi-bucket

terraform init
terraform apply -var-file="dev.tfvars"

# 3つのバケットが作成される
aws s3 ls | grep dev-bucket

# 削除
terraform destroy -var-file="dev.tfvars"
```

---

## 確認課題

1. モジュールを使って複数バケットを一度に作成できること。
2. `dev.tfvars` の `bucket_count` を変更して `plan` し、差分を確認する。
3. （任意）backend を S3 + DynamoDB に切り替えてみる。

---

## 次のステップ

→ [Day 5: Level 1 ワークショップ](../day05_workshop_level1/README.md)
