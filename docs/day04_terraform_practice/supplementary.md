# Day 4 補足: 実務で役立つ Terraform Tips

## 1. .gitignore に入れるべきファイル

```gitignore
# Terraform
.terraform/             # プロバイダのキャッシュ
*.tfstate               # ローカルstate
*.tfstate.backup        # state のバックアップ
.terraform.lock.hcl     # ※ チームで揃える場合はコミット推奨
terraform.tfvars        # 環境固有の変数（プロジェクトIDや秘密情報を含む可能性）
*.auto.tfvars
crash.log               # クラッシュログ
override.tf             # ローカル上書き
override.tf.json
```

## 2. .terraform.lock.hcl について

Terraform 0.14 以降、プロバイダのバージョンとハッシュをロックするファイルが作られます。これは **コミットすべき** ファイルで、チーム全員が同じプロバイダバージョンを使うのに役立ちます。

```bash
# 新しいプロバイダ・バージョンに更新するとき
terraform init -upgrade
```

## 3. tfvars の優先順位

複数の方法で変数を渡せます。優先順位は以下の通り（下にいくほど優先される）:

1. 環境変数 `TF_VAR_xxx`
2. `terraform.tfvars`
3. `terraform.tfvars.json`
4. `*.auto.tfvars` / `*.auto.tfvars.json`（アルファベット順）
5. コマンドライン `-var` / `-var-file`

## 4. workspace で環境を分ける（注意点あり）

```bash
terraform workspace new dev
terraform workspace new prod
terraform workspace select dev
```

`${terraform.workspace}` で現在のworkspace名を参照できますが、**実務ではディレクトリで分ける（envs/dev, envs/prod）方が推奨** されます。理由:

- workspace は state を分けるだけで、コードは共通
- 環境ごとに微妙に違うリソース構成にしたい場合、コード内に `if workspace == "prod"` のような分岐が増えて読みづらくなる

## 5. lifecycle ブロック

```hcl
resource "google_storage_bucket" "important" {
  name = "important-data"

  lifecycle {
    prevent_destroy = true       # 誤って destroy できないようにする
    ignore_changes  = [labels]   # この属性の差分を無視する
    create_before_destroy = true # 削除前に新リソースを作る（ダウンタイム回避）
  }
}
```

## 6. import で既存リソースを取り込む

コンソールで手動作成したリソースを Terraform 管理下に置く場合:

```bash
# Terraform 1.5+ の新しい構文
terraform import google_storage_bucket.hello PROJECT_ID/BUCKET_NAME
```

または `.tf` ファイルに `import` ブロックを書く:

```hcl
import {
  to = google_storage_bucket.hello
  id = "PROJECT_ID/BUCKET_NAME"
}
```

## 7. よくある落とし穴

| 症状 | 原因 |
| --- | --- |
| `terraform destroy` が失敗する | `force_destroy = false` のままオブジェクトが残っている、`deletion_protection = true` 等 |
| `terraform apply` 後に差分が出続ける | provider 側で自動付与される属性を Terraform が「変更」と認識している。`lifecycle { ignore_changes = [...] }` で抑制 |
| 認証エラー | `gcloud auth application-default login` を実行し直す |
| state lock エラー | 他の人が apply 中。完了を待つ。緊急時は `terraform force-unlock LOCK_ID` |
