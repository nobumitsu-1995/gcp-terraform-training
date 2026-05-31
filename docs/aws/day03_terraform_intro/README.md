# Day 3: Terraform入門

**ゴール**: TerraformでAWSリソースを作成・変更・削除できる。state とは何かを理解する。

---

## 1. Terraformとは

**Infrastructure as Code (IaC)** ツール。インフラの構成をコード（HCL: HashiCorp Configuration Language）で宣言的に記述し、その通りの状態を再現します。

- **宣言的**: 「どうやって作るか」ではなく「どうあるべきか」を書く
- **冪等性**: 同じコードを何度適用しても結果は同じ
- **provider**: AWS, GCP, Azure等のAPIを抽象化するプラグイン

> 💡 TerraformはマルチクラウドのIaCツールです。GCP版で学んだワークフロー（init/plan/apply/destroy）はそのまま使え、変わるのは **provider** と **リソースの種類** だけです。

---

## 2. 基本ワークフロー

```bash
terraform init      # プロバイダのダウンロード・初期化
terraform plan      # 変更内容のプレビュー
terraform apply     # 変更の適用
terraform destroy   # リソースの削除
```

---

## 3. HCL構文詳解

Terraformの設定はHCL (HashiCorp Configuration Language) という言語で記述します。人間にも機械にも読みやすいように設計されています。

#### 1. ブロックと引数

HCLの基本単位は **ブロック** です。ブロックは、特定のオブジェクト（リソースや変数など）を定義します。

```hcl
# ブロックタイプ "ブロックラベル" "ブロックラベル" { ... }
resource "aws_s3_bucket" "example" {
  # 引数 = 値
  bucket = "my-unique-bucket-12345"
  
  tags = {
    Name = "My bucket"
  }
}
```

- **ブロックタイプ (`resource`)**: 何を定義するか（リソース、変数、プロバイダなど）。
- **ブロックラベル (`"aws_s3_bucket"`, `"example"`)**: ブロックの具体的な種類や名前。
- **引数 (`bucket`, `tags`)**: ブロックの振る舞いを設定する値。`引数 = 値` の形式で記述します。

#### 2. データ型

引数には様々なデータ型が使えます。

- **文字列 (`string`)**: `"Hello, World!"`
- **数値 (`number`)**: `123`, `3.14`
- **真偽値 (`bool`)**: `true`, `false`
- **リスト (`list`)**: `["t2.micro", "t3.micro"]`
- **マップ (`map`)**: `{ Name = "web-server", Env = "dev" }`

```hcl
variable "bucket_config" {
  description = "バケットの設定"
  type = map(any)
  default = {
    name        = "my-bucket-from-variable"
    acl         = "private"
    versioning  = true
    tags        = {
      env = "dev"
      app = "web"
    }
  }
}

resource "aws_s3_bucket" "from_variable" {
  bucket = var.bucket_config.name
  acl    = var.bucket_config.acl
  tags   = var.bucket_config.tags

  versioning {
    enabled = var.bucket_config.versioning
  }
}
```

#### 3. 式 (Expressions)

値を直接書く代わりに、式を使って動的に値を生成できます。

- **他のリソース属性の参照**: `resource.<タイプ>.<名前>.<属性>`
  - 例: `aws_instance.web.public_ip`
- **変数の参照**: `var.<変数名>`
  - 例: `var.region`
- **データソースの参照**: `data.<タイプ>.<名前>.<属性>`
  - 例: `data.aws_caller_identity.current.account_id`
- **文字列テンプレート**: 文字列の中に `${...}` で式を埋め込めます。
  - 例: `bucket = "bucket-for-account-${data.aws_caller_identity.current.account_id}"`
- **組み込み関数**: Terraformには多数の[組み込み関数](https://developer.hashicorp.com/terraform/language/functions)があります。
  - 例: `upper("hello")` → `"HELLO"`
- **条件式**: `条件 ? trueの場合の値 : falseの場合の値`
  - 例: `var.is_production ? "t3.small" : "t3.micro"`

#### 4. 主要なブロックタイプ

| ブロック | 役割 |
| --- | --- |
| `terraform` | Terraform自体の設定（バージョン、バックエンド、プロバイダ要件） |
| `provider` | クラウドプロバイダ（`aws`, `google`など）の認証情報や設定 |
| `resource` | **作成・管理したいインフラリソース**（例: S3バケット、EC2インスタンス） |
| `data` | Terraform管理外の既存リソースや、他の場所で定義されたリソースを**読み取り専用で参照** |
| `variable` | 外部から設定を注入するための変数。`-var` オプションや `.tfvars` ファイルで値を渡せる |
| `output` | apply後に表示したい値（例: IPアドレス、バケット名）。他のTerraformスタックから参照も可能 |
| `locals` | `.tf` ファイル内でのみ使うローカル変数。複雑な式をDRYに保つのに役立つ |

#### 5. 実践的なサンプル

これらの要素を組み合わせると、より柔軟で再利用性の高いコードが書けます。

```hcl
# ----------------------------------------------------------------
# variables.tf
# ----------------------------------------------------------------
variable "region" {
  type        = string
  default     = "ap-northeast-1"
  description = "AWSリージョン"
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "環境名 (dev, stg, prd)"
}

# ----------------------------------------------------------------
# data.tf
# ----------------------------------------------------------------
# AWSアカウントIDを自動で取得
data "aws_caller_identity" "current" {}

# ----------------------------------------------------------------
# locals.tf
# ----------------------------------------------------------------
locals {
  # 共通のタグを定義
  common_tags = {
    owner       = "terraform-training"
    environment = var.environment
  }
  # バケット名を動的に生成
  bucket_name = "data-bucket-${data.aws_caller_identity.current.account_id}-${var.environment}"
}

# ----------------------------------------------------------------
# main.tf
# ----------------------------------------------------------------
provider "aws" {
  region = var.region
}

resource "aws_s3_bucket" "data_bucket" {
  bucket = local.bucket_name
  acl    = "private"
  tags   = local.common_tags

  # 本番環境だけオブジェクトロックを有効化
  object_lock_configuration {
    object_lock_enabled = var.environment == "prd" ? "Enabled" : null
  }
}

# ----------------------------------------------------------------
# outputs.tf
# ----------------------------------------------------------------
output "data_bucket_name" {
  value       = aws_s3_bucket.data_bucket.bucket
  description = "作成されたS3バケット名"
}
```

---

### `terraform init` の裏側：ファイルはいつ読み込まれるのか？

`cd` で入ったディレクトリで `terraform` コマンドを実行すると、Terraformはそのディレクトリにある `*.tf` という拡張子のファイルを **すべて** 読み込み、一つの大きな設定ファイルとして内部的に扱います。`main.tf` や `variables.tf` といったファイル名は、人間が分かりやすくするための慣習であり、Terraformの動作自体には影響しません。

その上で、各コマンドが何をしているかを見てみましょう。

`terraform init` の主な役割は、本格的なコードの評価を始める前の **準備** です。

1.  **プロバイダの検索とダウンロード**:
    Terraformはまず `*.tf` ファイル全体をスキャンし、`terraform { required_providers { ... } }` ブロックや `provider "aws" { ... }` ブロックを探します。そして、そこで宣言されているプロバイダ（例えば `hashicorp/aws`）を、インターネット上の [Terraform Registry](https://registry.terraform.io/) からダウンロードします。ダウンロードされたプラグインは、プロジェクトルートの `.terraform/providers` ディレクトリに保存されます。

2.  **バックエンドの初期化**:
    `terraform { backend "s3" { ... } }` のようなブロックがある場合、その設定に従ってリモートのStateファイルを読み書きするための準備をします。（これはDay 4で詳しく学びます）

重要なのは、`init` の段階では **リソースの具体的な内容（`resource "aws_s3_bucket"` の `bucket` や `acl` など）はまだ深く評価されない** という点です。`init` はあくまで、コードを実行するための「調理器具（プロバイダ）」を揃える段階です。

実際にすべてのリソース定義、変数、ローカル変数が評価され、それらの依存関係が解決されるのは、`terraform plan` や `terraform apply` を実行したときです。この段階で、Terraformは全 `.tf` ファイルから集めた情報を使って依存関係グラフを構築し、「どのリソースを」「どの順番で」「どのような属性で」作成・変更すべきかを判断します。

## 4. ハンズオン: 最初のバケットを作る

使用するコード: [examples/hello-bucket/](./examples/hello-bucket/)

S3バケット名はグローバルで一意である必要があるため、サンプルでは `aws_caller_identity` データソースでアカウントIDを取得し、それを接頭辞にして一意な名前を組み立てています。

```bash
cd examples/hello-bucket

# 初期化
terraform init

# プレビュー
terraform plan

# 適用
terraform apply

# 確認
aws s3 ls

# 削除
terraform destroy
```

---

## 5. state とは

Terraform は `terraform.tfstate` ファイルで「現実のインフラ」と「コード」の対応を管理します。

- **state**: 現在のインフラの状態を記録するJSONファイル
- **drift**: コードとstateの乖離。`terraform plan` で検出される
- **リモートstate**: チームで共有するため、S3 + DynamoDB 等に保存する（Day 4で扱う）

⚠️ `terraform.tfstate` には機密情報が含まれることがあります。**Git にコミットしない**でください（`.gitignore` に追加）。

---

## 確認課題

1. `terraform apply` でバケットを作成できること。
2. `terraform.tfstate` の中身を見て、リソース情報が記録されていることを確認する。
3. `terraform destroy` でリソースを削除できること。

---

## 次のステップ

→ [Day 4: Terraform実践（モジュール・変数・backend）](../day04_terraform_practice/README.md)
