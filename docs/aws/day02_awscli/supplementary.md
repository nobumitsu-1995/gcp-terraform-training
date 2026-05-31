# Day 2 補足: AWS CLI チートシート

## アカウント・認証

```bash
aws sts get-caller-identity            # 現在の認証情報（アカウントID・ARN）を確認
aws configure --profile NAME           # プロファイル作成（対話式）
aws configure list-profiles            # プロファイル一覧
aws configure list                     # 現在の有効な設定を表示
aws sso login --profile NAME           # IAM Identity Center でログイン
```

## プロファイル切り替え

```bash
aws s3 ls --profile NAME               # コマンド単位で切り替え
export AWS_PROFILE=NAME                # シェル単位で切り替え
export AWS_REGION=ap-northeast-1       # リージョンを環境変数で上書き
```

## S3 (aws s3 / s3api)

```bash
aws s3 mb s3://BUCKET --region ap-northeast-1   # バケット作成
aws s3 ls                                       # バケット一覧
aws s3 cp FILE s3://BUCKET/                      # アップロード
aws s3 sync DIR s3://BUCKET/                     # ディレクトリ同期
aws s3 rb s3://BUCKET --force                    # バケット削除（中身ごと）
```

## EC2

```bash
aws ec2 describe-instances                       # インスタンス一覧
aws ec2 run-instances ...                        # インスタンス作成
aws ec2 describe-regions --query "Regions[].RegionName"  # リージョン一覧
```

## IAM

```bash
aws iam list-users                               # ユーザー一覧
aws iam list-roles                               # ロール一覧
aws iam list-attached-user-policies --user-name NAME  # ユーザーのポリシー確認
```

## よく使うグローバルオプション

```bash
--profile NAME       # 使用プロファイル
--region REGION      # 対象リージョン
--output json|table|text   # 出力形式
--query "..."        # JMESPath で出力をフィルタ（例: --query "Account"）
```

## GCPとの対応（gcloud → aws）

| 操作 | GCP | AWS |
| --- | --- | --- |
| 初期設定 | `gcloud init` | `aws configure` |
| 認証確認 | `gcloud auth list` | `aws sts get-caller-identity` |
| 設定切り替え | `gcloud config configurations activate` | `export AWS_PROFILE=...` |
| ストレージ操作 | `gsutil` | `aws s3` |
| API有効化 | `gcloud services enable` | （概念なし。IAMで制御） |

（補足ファイルはここまで）
