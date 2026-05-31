# Day 4 補足: モジュール設計とbackendパターン

## モジュールのinput/output設計

モジュールは「入力（variables）」と「出力（outputs）」で外部とやり取りします。内部実装は隠蔽します。

```hcl
# モジュール呼び出し側
module "bucket" {
  source = "./modules/s3_bucket"
  name   = "my-bucket"
}

# モジュールの出力を参照
output "arn" {
  value = module.bucket.arn
}
```

## count と for_each

```hcl
# count: 数を指定して複製
resource "aws_s3_bucket" "a" {
  count  = 3
  bucket = "bucket-${count.index}"
}

# for_each: マップ/セットで複製（キーで管理できる）
resource "aws_s3_bucket" "b" {
  for_each = toset(["logs", "data", "backup"])
  bucket   = "bucket-${each.key}"
}
```

## backendの種類

| backend | 用途 |
| --- | --- |
| local | デフォルト。ローカルファイル |
| s3 | AWS。S3 + DynamoDB（ロック） |
| gcs | GCP。GCSバケットに保存 |
| remote | Terraform Cloud |

## 状態のロック

S3 backend は `dynamodb_table` を指定すると、DynamoDB の項目でロックを行い、複数人の同時applyによる破損を防ぎます。

## tfvars の使い分け

```
dev.tfvars    # 開発環境
staging.tfvars
prod.tfvars   # 本番環境
```

```bash
terraform apply -var-file="prod.tfvars"
```

## ディレクトリ分割パターン

```
environments/
├── dev/
│   └── main.tf      # module を呼ぶだけ
├── staging/
└── prod/
modules/
└── ...
```

（以下略）
