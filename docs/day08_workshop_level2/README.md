# Day 8: Level 2 ワークショップ — サーバーレスデータパイプライン

## ビジネスシナリオ

> **シチュエーション**: あなたはECサイトを運営する会社のデータエンジニアリングチームに配属されました。営業部門から「各店舗の売上CSVファイルを毎日手動でExcelに取り込んで集計しているのを自動化してほしい。ダッシュボードですぐに最新の売上を見られるようにしたい」という要望があります。
>
> **あなたの課題**: CSVファイルをGCSにアップロードするだけで自動的にETL処理が走り、BigQueryに加工済みデータが投入されるパイプラインを構築してください。GCSイベントをCloud Functionsで検知し、Pub/Subでキューイングし、Cloud RunのETLワーカーでデータ加工・投入を行います。Looker StudioからBigQueryに接続すれば、営業部門がいつでも最新データを確認できるようになります。

## 課題構成図

![Level 2 構成図](./architecture.png)

詳細解説は [architecture.md](./architecture.md) を参照。

---

## 使用するGCPサービス

| GCPサービス            | 役割                                 | AWSでの対応サービス | 無料枠内か          |
| ---------------------- | ------------------------------------ | ------------------- | ------------------- |
| Cloud Storage (GCS)    | CSV受け取りバケット                  | S3                  | ○                   |
| Cloud Functions (Gen2) | GCSイベント → Pub/Sub publish        | Lambda              | ○（200万回/月）     |
| Pub/Sub                | Functions → Cloud Run の非同期キュー | SNS + SQS           | ○（10GB/月）        |
| Cloud Run              | ETLワーカー（CSV加工→BQロード）      | ECS Fargate         | ○（180k vCPU秒/月） |
| Artifact Registry      | Cloud Runイメージの保管              | ECR                 | ○（500MB）          |
| BigQuery               | 加工済みデータの保存・分析           | Redshift / Athena   | ○（1TB/月クエリ）   |
| IAM + Service Account  | 最小権限のアクセス制御               | IAM Role            | ○                   |

---

## なぜこの構成なのか

### 「CSVが来たら処理する、だけなのになぜCloud FunctionsとCloud Runの2段構成なのか」

「Cloud Functions 1つでGCSイベント検知からBigQueryロードまで全部やればいいのでは？」という疑問は自然です。技術的には可能ですが、分けているのには理由があります:

- **Cloud Functionsの制約**: 最大タイムアウトが540秒（9分）、メモリ上限も限られています。CSVファイルが大きくなるとタイムアウトのリスクがあります。一方、Cloud Runはタイムアウト最大60分、メモリも最大32GBまでスケールできます
- **責務の分離**: Cloud Functionsは「イベントを検知して通知する」という軽い仕事だけに集中し、Cloud Runは「重いETL処理を実行する」という仕事に集中します。片方だけ修正・デプロイしたいときに影響範囲が小さくなります
- **リトライ戦略が異なる**: イベント検知の失敗（一時的なGCS障害）と、ETL処理の失敗（データ不正、BQ一時障害）では適切なリトライ戦略が違います。間にPub/Subを挟むことで、それぞれ独立してリトライ設定ができます

### 「なぜCloud FunctionsからCloud Runを直接HTTPで呼ばず、間にPub/Subを挟むのか」

直接HTTP呼び出しにすると、以下の問題が起きます:

- **同期的な結合**: Cloud FunctionsがCloud Runの処理完了を待つため、ETLが遅いとCloud Functions側もタイムアウトする（障害の連鎖）
- **負荷制御ができない**: CSVが100ファイル同時にアップロードされると、100個のCloud Runインスタンスが同時起動してBigQueryに同時書き込みし、レート制限に引っかかる可能性がある
- **リトライの責任が曖昧**: Cloud Runが500エラーを返したとき、Cloud Functions側でリトライするのか？何回？間隔は？

Pub/Subを挟むことで:

- **非同期に疎結合**: Cloud Functionsはメッセージをpublishした時点で完了。ETLの成否を知る必要がない
- **自動リトライ**: Pub/Subがメッセージ配信を保証し、Cloud Runが失敗したら自動でリトライする
- **バックプレッシャー**: Cloud Runの `max_instance_count` でETLの同時実行数を制限でき、バックエンドへの負荷を制御できる
- **Dead Letter Queue**: 何度リトライしても失敗するメッセージをDLQに退避して、正常なメッセージの処理を止めない

これは「イベント駆動アーキテクチャ」と呼ばれる設計パターンで、マイクロサービス間の通信で広く採用されています。

### 「BigQueryに直接CSVをインポートすればいいのでは？」

BigQueryの `bq load` コマンドやコンソールからCSVを直接インポートする機能はあります。しかし実務では:

- CSVのフォーマット不備（文字化け、列ズレ、型不一致）を事前にバリデーション・修正する必要がある
- 複数の店舗から異なるフォーマットのCSVが来る場合、正規化処理が必要
- 重複データの排除やタイムスタンプの付与など、ビジネスロジックに依存する加工がある

こうした「Extract（抽出）→ Transform（変換）→ Load（投入）」の処理を自動化するのがETLパイプラインの役割です。

---

## 要件

1. Raw CSVを受け取るGCSバケットを作成する
2. GCSアップロードをトリガーにCloud Functions（Gen2, Node.js）を起動し、Pub/Subにpublishする
3. Cloud Run ETL worker が Pub/Sub push subscription 経由でCSVを加工しBigQueryにロードする
4. コンテナイメージは Artifact Registry で管理する
5. サービスアカウントを作成し、最小権限のIAMロールを付与する
6. すべてTerraformで構築する

---

## 実装ガイド

- Terraformコード: [examples/terraform/](./examples/terraform/)
- Cloud Functions ソース: [examples/functions/](./examples/functions/)
- ETL Worker ソース: [examples/etl-worker/](./examples/etl-worker/)

### デプロイ手順の概要

```bash
# 1. Functions のZIP化
cd examples/functions
zip -r ../terraform/csv-trigger.zip .
cd -

# 2. ETL Worker のイメージビルド & プッシュ
cd examples/etl-worker
docker build -t asia-northeast1-docker.pkg.dev/${PROJECT}/training-repo/etl-worker:v1 .
docker push   asia-northeast1-docker.pkg.dev/${PROJECT}/training-repo/etl-worker:v1
cd -

# 3. Terraform apply
cd examples/terraform
terraform init
terraform apply -var="project_id=${PROJECT}"

# 4. 動作確認: CSV を Raw バケットにアップロード
echo 'order_id,customer,product,amount,status,created_at
ORD-001,tanaka,pizza,2500,received,2026-05-28T00:00:00Z
ORD-002,sato,salad,800,received,2026-05-28T00:00:01Z' > sample.csv
gsutil cp sample.csv gs://${PROJECT}-raw-csv/
```

数十秒待ってから:

```bash
bq query --use_legacy_sql=false "SELECT * FROM pipeline_data.orders"
```

---

## 完了条件チェックリスト

- [ ] GCSバケットにCSVをアップロードすると Cloud Functions が起動する
- [ ] Pub/Sub経由でCloud Run ETLワーカーが呼び出される
- [ ] BigQueryテーブルにデータが投入される
- [ ] `SELECT * FROM pipeline_data.orders` でデータを確認できる
- [ ] **`terraform destroy` で全リソース削除**

---

## 次のステップ

→ [Day 9: ネットワーク・DB・セキュリティ](../day09_network_security/README.md)
