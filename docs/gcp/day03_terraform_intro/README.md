# Day 3: Terraform入門

**ゴール**: IaCの意義とTerraformの基本サイクル（init → plan → apply → destroy）を理解する。

---

## 1. 座学トピック

### Infrastructure as Code (IaC) とは

「インフラ構成をコードで宣言的に管理する」考え方。手動構築（コンソールでポチポチ）に対して以下の利点があります。

- **再現性**: 同じコードから同じ環境を何度でも作れる
- **レビュー可能**: Pull Request でインフラ変更をレビューできる
- **バージョン管理**: Git で履歴・差分・ロールバックが追える
- **ドキュメント化**: コード自体が現状の構成のドキュメントになる

### Terraform のアーキテクチャ

```
あなたのコード (.tf)  →  terraform CLI  →  Provider (例: hashicorp/google)  →  クラウドAPI
                            ↓
                       state ファイル
                       （現在のインフラ状態を記録）
```

- **Provider**: AWS, GCP, Azure などのクラウドAPIをラップするプラグイン
- **Resource**: クラウド上のリソース（GCSバケット、Cloud Runサービス等）
- **State**: 実際のリソースと .tf コードの対応関係を記録するファイル

### HCL構文詳解

Terraformの設定はHCL (HashiCorp Configuration Language) という言語で記述します。人間にも機械にも読みやすいように設計されています。

#### 1. ブロックと引数

HCLの基本単位は **ブロック** です。ブロックは、特定のオブジェクト（リソースや変数など）を定義します。

```hcl
# ブロックタイプ "ブロックラベル" "ブロックラベル" { ... }
resource "google_storage_bucket" "example" {
  # 引数 = 値
  name     = "my-unique-bucket-12345"
  location = "US-CENTRAL1"
}
```

- **ブロックタイプ (`resource`)**: 何を定義するか（リソース、変数、プロバイダなど）。
- **ブロックラベル (`"google_storage_bucket"`, `"example"`)**: ブロックの具体的な種類や名前。
- **引数 (`name`, `location`)**: ブロックの振る舞いを設定する値。`引数 = 値` の形式で記述します。

#### 2. データ型

引数には様々なデータ型が使えます。

- **文字列 (`string`)**: `"Hello, World!"`
- **数値 (`number`)**: `123`, `3.14`
- **真偽値 (`bool`)**: `true`, `false`
- **リスト (`list`)**: `["apple", "banana", "cherry"]`
- **マップ (`map`)**: `{ key = "value", name = "John" }`

```hcl
variable "bucket_config" {
  description = "バケットの設定"
  type = map(any)
  default = {
    name        = "my-bucket-from-variable"
    storage_class = "STANDARD"
    enable_versioning = true
    tags = ["dev", "web"]
  }
}

resource "google_storage_bucket" "from_variable" {
  name          = var.bucket_config.name
  location      = "US-CENTRAL1"
  storage_class = var.bucket_config.storage_class

  versioning {
    enabled = var.bucket_config.enable_versioning
  }
}
```

#### 3. 式 (Expressions)

値を直接書く代わりに、式を使って動的に値を生成できます。

- **他のリソース属性の参照**: `resource.<タイプ>.<名前>.<属性>`
  - 例: `google_project.my_project.project_id`
- **変数の参照**: `var.<変数名>`
  - 例: `var.project_id`
- **ローカル変数の参照**: `local.<ローカル変数名>`
  - 例: `local.common_tags`
- **文字列テンプレート**: 文字列の中に `${...}` で式を埋め込めます。
  - 例: `name = "bucket-for-${var.project_id}"`
- **組み込み関数**: Terraformには多数の[組み込み関数](https://developer.hashicorp.com/terraform/language/functions)があります。
  - 例: `upper("hello")` → `"HELLO"`
- **条件式**: `条件 ? trueの場合の値 : falseの場合の値`
  - 例: `var.is_production ? "STANDARD" : "NEARLINE"`

#### 4. 主要なブロックタイプ

| ブロック    | 役割                                                                                     |
| ----------- | ---------------------------------------------------------------------------------------- |
| `terraform` | Terraform自体の設定（バージョン、バックエンド、プロバイダ要件）                          |
| `provider`  | クラウドプロバイダ（`google`, `aws`など）の認証情報や設定                                |
| `resource`  | **作成・管理したいインフラリソース**（例: GCSバケット、VMインスタンス）                  |
| `data`      | Terraform管理外の既存リソースや、他の場所で定義されたリソースを**読み取り専用で参照**    |
| `variable`  | 外部から設定を注入するための変数。`-var` オプションや `.tfvars` ファイルで値を渡せる     |
| `output`    | apply後に表示したい値（例: IPアドレス、バケット名）。他のTerraformスタックから参照も可能 |
| `locals`    | `.tf` ファイル内でのみ使うローカル変数。複雑な式をDRYに保つのに役立つ                    |

#### 5. 実践的なサンプル

これらの要素を組み合わせると、より柔軟で再利用性の高いコードが書けます。

```hcl
# ----------------------------------------------------------------
# variables.tf
# ----------------------------------------------------------------
variable "project_id" {
  type        = string
  description = "GCPプロジェクトID"
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "環境名 (dev, stg, prd)"
}

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
  bucket_name = "data-bucket-${var.project_id}-${var.environment}"
}

# ----------------------------------------------------------------
# main.tf
# ----------------------------------------------------------------
provider "google" {
  project = var.project_id
}

resource "google_storage_bucket" "data_bucket" {
  name          = local.bucket_name
  location      = "ASIA-NORTHEAST1"
  storage_class = var.environment == "prd" ? "STANDARD" : "NEARLINE" # 本番環境だけSTANDARD
  labels        = local.common_tags

  # バージョニングを有効化
  versioning {
    enabled = true
  }
}

# ----------------------------------------------------------------
# outputs.tf
# ----------------------------------------------------------------
output "data_bucket_name" {
  value       = google_storage_bucket.data_bucket.name
  description = "作成されたGCSバケット名"
}
```

### コマンドサイクル

| コマンド             | 役割                                    |
| -------------------- | --------------------------------------- |
| `terraform init`     | プロバイダのダウンロード、backend初期化 |
| `terraform fmt`      | HCLコードを自動整形                     |
| `terraform validate` | 構文・型チェック                        |
| `terraform plan`     | 差分プレビュー（**何も変更しない**）    |
| `terraform apply`    | 実際にリソースを作成/変更               |
| `terraform destroy`  | リソースを全削除                        |
| `terraform output`   | output値を表示                          |
| `terraform show`     | 現在のstateを表示                       |

### `terraform plan` の読み方

```
+ google_storage_bucket.hello   ← 新規作成
- google_storage_bucket.old      ← 削除
~ google_storage_bucket.hello   ← 変更（in-place）
-/+ google_storage_bucket.hello ← 削除して再作成
```

### `terraform init` の裏側：ファイルはいつ読み込まれるのか？

`cd` で入ったディレクトリで `terraform` コマンドを実行すると、Terraformはそのディレクトリにある `*.tf` という拡張子のファイルを **すべて** 読み込み、一つの大きな設定ファイルとして内部的に扱います。`main.tf` や `variables.tf` といったファイル名は、人間が分かりやすくするための慣習であり、Terraformの動作自体には影響しません。

その上で、各コマンドが何をしているかを見てみましょう。

`terraform init` の主な役割は、本格的なコードの評価を始める前の **準備** です。

1.  **プロバイダの検索とダウンロード**:
    Terraformはまず `*.tf` ファイル全体をスキャンし、`terraform { required_providers { ... } }` ブロックや `provider "google" { ... }` ブロックを探します。そして、そこで宣言されているプロバイダ（例えば `hashicorp/google`）を、インターネット上の [Terraform Registry](https://registry.terraform.io/) からダウンロードします。ダウンロードされたプラグインは、プロジェクトルートの `.terraform/providers` ディレクトリに保存されます。

2.  **バックエンドの初期化**:
    `terraform { backend "gcs" { ... } }` のようなブロックがある場合、その設定に従ってリモートのStateファイルを読み書きするための準備をします。（これはDay 4で詳しく学びます）

重要なのは、`init` の段階では **リソースの具体的な内容（`resource "google_storage_bucket"` の `location` や `name` など）はまだ深く評価されない** という点です。`init` はあくまで、コードを実行するための「調理器具（プロバイダ）」を揃える段階です。

実際にすべてのリソース定義、変数、ローカル変数が評価され、それらの依存関係が解決されるのは、`terraform plan` や `terraform apply` を実行したときです。この段階で、Terraformは全 `.tf` ファイルから集めた情報を使って依存関係グラフを構築し、「どのリソースを」「どの順番で」「どのような属性で」作成・変更すべきかを判断します。

### Stateファイルの注意

- 手動で編集してはいけない（壊れる）
- Git にコミットしてはいけない（パスワード等が含まれる）
- チームで共有するときは Remote Backend（GCS等）を使う（Day 4で学習）

---

## 2. AWS経験者向け: Provider比較 Tips

Terraformはクラウドプロバイダごとに `provider` を差し替えるだけで同じワークフローが使えます。AWS との差異は [supplementary.md](./supplementary.md) を参照。

---

## 3. ハンズオン — 最初のTerraformコード

サンプルコード一式: [examples/hello-bucket/](./examples/hello-bucket/)

Terraformの変数は、`TF_VAR_<変数名>` という環境変数を設定しておくと、自動的に読み込まれます。これを利用して、GCPプロジェクトIDを渡しましょう。

```bash
# ターミナルで環境変数を設定
# (Day1で設定した GOOGLE_CLOUD_PROJECT を使います)
export TF_VAR_project_id=$GOOGLE_CLOUD_PROJECT

# サンプルコードのディレクトリへ移動
cd docs/gcp/day03_terraform_intro/examples/hello-bucket

# 1. プロバイダのダウンロード
terraform init

# 2. 構文整形・検証
terraform fmt
terraform validate

# 3. 差分プレビュー
# project_id は環境変数から自動で渡されます
terraform plan

# 4. リソース作成
terraform apply

# 5. 出力値の確認
terraform output

# 6. 後片付け
terraform destroy
```

ファイル構成:

| ファイル       | 役割                                          |
| -------------- | --------------------------------------------- |
| `terraform.tf` | Terraform本体のバージョン制約、Providerの宣言 |
| `variables.tf` | 入力変数の定義                                |
| `main.tf`      | リソース定義（GCSバケット）                   |
| `outputs.tf`   | 出力値の定義                                  |

---

## 確認課題

`terraform plan` の出力を読み、作成されるリソースの属性を1つずつ説明できること。

---

## 次のステップ

→ [Day 4: Terraform実践パターン](../day04_terraform_practice/README.md)
