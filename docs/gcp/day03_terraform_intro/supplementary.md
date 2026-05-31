# Day 3 補足: AWS経験者向け Provider 比較

Terraformはクラウドプロバイダごとに `provider` を差し替えるだけで同じワークフローが使えます。AWSの資料やチュートリアルを見たことがある人向けに、差異を整理しておきます。

## GCPの場合（本研修で使用）

```hcl
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"   # GCP用プロバイダ
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = "my-gcp-project"        # GCPはプロジェクト単位でリソースを管理
  region  = "asia-northeast1"       # 東京リージョン
}

# GCSバケット（AWSでいう S3バケット）
resource "google_storage_bucket" "example" {
  name     = "my-bucket"
  location = "asia-northeast1"
}
```

## AWSの場合（参考。本研修では使わない）

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"    # AWS用プロバイダ
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = "ap-northeast-1"       # 東京リージョン（GCPとリージョン名が違う）
  profile = "default"              # AWSは ~/.aws/credentials のプロファイルで認証
}

# S3バケット（GCPでいう GCSバケット）
resource "aws_s3_bucket" "example" {
  bucket = "my-bucket"
}
```

## 主な違いのまとめ

| 観点 | GCP | AWS |
| --- | --- | --- |
| **認証** | `gcloud auth application-default login` | `~/.aws/credentials` または環境変数 |
| **スコープ** | `project` 単位 | `account` + `region` 単位 |
| **リソース命名** | `google_*` | `aws_*` |
| **リージョン名** | `asia-northeast1` | `ap-northeast-1` |
| **HCL構文自体** | 完全に同じ。`variable`, `output`, `module`, `for_each`, `count` などはプロバイダに依存しない |  |

## なぜ provider のバージョン固定が重要か

`version = "~> 5.0"` は「5.x.x 系の最新を使う」という意味です。Provider のバージョンを固定しないと、ある日突然 `terraform apply` が壊れる可能性があります。

| 記法 | 意味 |
| --- | --- |
| `= 5.4.0` | 完全一致 |
| `~> 5.4` | 5.x 系の最新（5.4以上、6.0未満） |
| `~> 5.4.0` | 5.4.x 系の最新（5.4.0以上、5.5未満） |
| `>= 5.0, < 6.0` | 範囲指定 |

実務では `~> 5.0` のような緩やかな指定で始め、CI/CDで自動テストを回しながら追従するのが一般的です。
