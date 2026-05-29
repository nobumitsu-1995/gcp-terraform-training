# Day 2 補足: gcloud / gsutil チートシート

研修中に頻繁に使うコマンドをまとめておきます。

## 認証関連

| 用途 | コマンド |
| --- | --- |
| ログイン（CLI用） | `gcloud auth login` |
| アプリケーションデフォルト認証（Terraform用） | `gcloud auth application-default login` |
| 認証済みアカウント一覧 | `gcloud auth list` |
| アクティブアカウント切替 | `gcloud config set account ACCOUNT` |
| アクセストークン取得 | `gcloud auth print-access-token` |

## configuration / 設定

| 用途 | コマンド |
| --- | --- |
| configuration 一覧 | `gcloud config configurations list` |
| 作成 | `gcloud config configurations create NAME` |
| 切替 | `gcloud config configurations activate NAME` |
| 現在の設定確認 | `gcloud config list` |
| プロジェクト設定 | `gcloud config set project PROJECT_ID` |
| リージョン設定 | `gcloud config set compute/region asia-northeast1` |

## プロジェクト / API

| 用途 | コマンド |
| --- | --- |
| プロジェクト一覧 | `gcloud projects list` |
| プロジェクト作成 | `gcloud projects create PROJECT_ID --name=NAME` |
| 有効なAPI一覧 | `gcloud services list --enabled` |
| API有効化 | `gcloud services enable SERVICE.googleapis.com` |
| API無効化 | `gcloud services disable SERVICE.googleapis.com` |

## GCS (gsutil)

| 用途 | コマンド |
| --- | --- |
| バケット作成 | `gsutil mb -l REGION gs://BUCKET/` |
| バケット一覧 | `gsutil ls` |
| バケット内一覧 | `gsutil ls gs://BUCKET/` |
| ファイルアップロード | `gsutil cp FILE gs://BUCKET/` |
| ディレクトリ再帰アップロード | `gsutil -m cp -r DIR gs://BUCKET/` |
| ファイルダウンロード | `gsutil cp gs://BUCKET/FILE .` |
| ファイル削除 | `gsutil rm gs://BUCKET/FILE` |
| バケット削除 | `gsutil rm -r gs://BUCKET/` |
| 公開URL付与 | `gsutil acl ch -u AllUsers:R gs://BUCKET/FILE` |

## Cloud Run

| 用途 | コマンド |
| --- | --- |
| サービス一覧 | `gcloud run services list` |
| サービスのURL取得 | `gcloud run services describe NAME --region=REGION --format='value(status.url)'` |
| ログ表示 | `gcloud run services logs read NAME --region=REGION` |
| デプロイ | `gcloud run deploy NAME --image=... --region=REGION` |

## IAM

| 用途 | コマンド |
| --- | --- |
| プロジェクトのIAMポリシー取得 | `gcloud projects get-iam-policy PROJECT_ID` |
| ロール追加 | `gcloud projects add-iam-policy-binding PROJECT_ID --member=MEMBER --role=ROLE` |
| ロール削除 | `gcloud projects remove-iam-policy-binding PROJECT_ID --member=MEMBER --role=ROLE` |

## トラブルシューティング

| 症状 | 原因と対処 |
| --- | --- |
| `Permission denied` | プロジェクトIDが間違っているか、ロール不足。`gcloud config list` でアクティブな設定を確認 |
| `API has not been used` | 該当APIが有効化されていない。`gcloud services enable XXX.googleapis.com` |
| `Your default credentials were not found` | Terraform実行時のエラー。`gcloud auth application-default login` を実行 |
