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

### HCL構文の基礎

```hcl
# resource: 作成するリソース
resource "TYPE" "NAME" {
  attribute = "value"
}

# data: 既存リソースの参照（読み取り専用）
data "TYPE" "NAME" {
  filter = "..."
}

# variable: 外部から渡す変数
variable "name" {
  type    = string
  default = "training"
}

# output: 他のスタックや人間向けの出力
output "url" {
  value = resource.foo.url
}

# locals: 内部用の計算式
locals {
  bucket_name = "${var.project}-${var.env}"
}
```

### コマンドサイクル

| コマンド | 役割 |
| --- | --- |
| `terraform init` | プロバイダのダウンロード、backend初期化 |
| `terraform fmt` | HCLコードを自動整形 |
| `terraform validate` | 構文・型チェック |
| `terraform plan` | 差分プレビュー（**何も変更しない**） |
| `terraform apply` | 実際にリソースを作成/変更 |
| `terraform destroy` | リソースを全削除 |
| `terraform output` | output値を表示 |
| `terraform show` | 現在のstateを表示 |

### `terraform plan` の読み方

```
+ google_storage_bucket.hello   ← 新規作成
- google_storage_bucket.old      ← 削除
~ google_storage_bucket.hello   ← 変更（in-place）
-/+ google_storage_bucket.hello ← 削除して再作成
```

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

```bash
cd docs/day03_terraform_intro/examples/hello-bucket

# 1. プロバイダのダウンロード
terraform init

# 2. 構文整形・検証
terraform fmt
terraform validate

# 3. 差分プレビュー
terraform plan -var="project_id=YOUR_PROJECT_ID"

# 4. リソース作成
terraform apply -var="project_id=YOUR_PROJECT_ID"

# 5. 出力値の確認
terraform output

# 6. 後片付け
terraform destroy -var="project_id=YOUR_PROJECT_ID"
```

ファイル構成:

| ファイル | 役割 |
| --- | --- |
| `terraform.tf` | Terraform本体のバージョン制約、Providerの宣言 |
| `variables.tf` | 入力変数の定義 |
| `main.tf` | リソース定義（GCSバケット） |
| `outputs.tf` | 出力値の定義 |

---

## 確認課題

`terraform plan` の出力を読み、作成されるリソースの属性を1つずつ説明できること。

---

## 次のステップ

→ [Day 4: Terraform実践パターン](../day04_terraform_practice/README.md)
