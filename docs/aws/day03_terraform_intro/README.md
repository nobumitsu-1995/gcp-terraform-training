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

## 3. HCLの基本構造

```hcl
# プロバイダの設定
provider "aws" {
  region = "ap-northeast-1"
}

# リソースの定義
resource "aws_s3_bucket" "example" {
  bucket = "my-unique-bucket-name"
}
```

> 💡 認証情報はコードに書きません。Day 0/2 で設定した `AWS_PROFILE`（または環境変数のアクセスキー）をproviderが自動的に使います。

---

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
