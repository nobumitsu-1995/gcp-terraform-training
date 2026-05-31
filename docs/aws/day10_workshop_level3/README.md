# Day 10: Level 3 ワークショップ — マイクロサービス基盤

**API Gateway + Lambda + SNS/SQS多段キュー + RDS + Athena**

## ビジネスシナリオ

> **シチュエーション**: あなたは急成長中のフードデリバリーサービス「QuickBite」のバックエンド開発チームに所属しています。これまでモノリシックなアプリで運用していましたが、注文数が急増し、以下の問題が発生しています:
>
> - 注文処理が集中するとレスポンスが悪化する
> - 決済処理の障害が通知機能まで巻き込んでサービス全体が停止する
> - 新機能のデプロイが全サービスの再デプロイを必要とし、リリースサイクルが遅い
>
> CTOから「マイクロサービスアーキテクチャに移行して、各サービスを独立してスケール・デプロイできるようにしたい。APIの入口はAPI Gatewayで一元管理し、サービス間通信はメッセージキューで疎結合にして障害の伝播を防ぎたい」という方針が出ました。
>
> **あなたの課題**: API Gatewayで外部リクエストを受け、Lambdaの各マイクロサービスにルーティングする注文処理基盤をTerraformで構築してください。

## 課題構成図

詳細解説は [architecture.md](./architecture.md) を参照。

```
User → API Gateway (HTTP API)
         → order-svc (Lambda, VPC) → RDS + SNS `orders`
             → SQS → processing-svc (Lambda) → S3 + Athena + SNS `processed`
                 → SQS → notify-svc (Lambda)
```

---

## 使用するAWSサービスと役割

| AWSサービス | 役割 | GCPでの対応 | コスト注意 |
| --- | --- | --- | --- |
| API Gateway (HTTP API) | ルーティング・入口 | API Gateway | 従量（$1/100万リクエスト） |
| Lambda × 3 | order / processing / notify | Cloud Run × 3 | ほぼ無料枠 |
| SNS + SQS × 2系統 | orders / processed の多段キュー | Pub/Sub × 2 | 無料枠内 |
| RDS (PostgreSQL) | 注文データRDB | Cloud SQL | **時間課金。db.t3.micro** |
| S3 + Athena (Glue) | 加工済みデータ・分析 | GCS + BigQuery | 無料枠内 |
| VPC + NAT Gateway | Lambda → RDS のプライベート接続 | VPC + VPCコネクタ | **NATは時間課金** |
| Secrets Manager | DB認証情報 | Secret Manager | 月$0.40 |
| IAM Role | サービス間認証・認可 | IAM + SA | 無料 |

---

## なぜこの構成なのか

### 「なぜモノリスを3つのLambdaに分けるのか」

QuickBiteの問題を振り返ると:

- 注文処理が集中するとレスポンス悪化 → **受付と後続処理を分離すれば、受付は即座に返せる**
- 決済障害が通知まで巻き込む → **サービスが分かれていれば、processing-svc が落ちても order/notify は影響を受けない**
- デプロイが全体に波及 → **サービスごとに独立してデプロイ・スケールできる**

### 「なぜ order-svc から processing-svc を直接呼ばず、SNS/SQSを挟むのか」

```
× 同期呼び出し（密結合）:
  User → API GW → order → processing → notify → User
  問題: processingが3秒かかるとユーザーが3秒待つ。障害が全体に波及。

○ 非同期（疎結合）:
  User → API GW → order → 202 Accepted（即返す）
                    ↓ (非同期)
                SNS orders → SQS → processing → SNS processed → SQS → notify
```

- **レスポンス高速**: order-svc は「受け付けました」を即返す
- **障害の隔離**: processing-svc がダウンしても受付は止まらない
- **スケールの独立**: 注文急増時も order-svc だけスケールすればよい
- **リトライ**: SQS が失敗メッセージを可視性タイムアウト後に再配信

### 「なぜキューを2系統（orders / processed）に分けるのか」

`orders` は processing-svc が、`processed` は notify-svc が購読します。将来「在庫管理」「分析」「ポイント付与」などのサービスを追加するとき、該当トピックにSQSを足すだけで既存サービスに影響しません（fan-out）。

### 「なぜ API Gateway を自作せず使うのか」

- ルーティング・認証・レート制限・スロットリングがマネージドで手に入る
- Lambdaプロキシ統合でバックエンドを差し替えやすい
- インスタンス管理・スケーリング不要

### 「VPC と NAT Gateway は何のために必要か」

RDSをセキュリティのためプライベート（`publicly_accessible = false`）にしているため、order-svc Lambda は VPC内に配置してRDSへ接続します。VPC内のLambdaが SNS や Secrets Manager（パブリックなAWS API）へ到達するには、NAT Gateway 経由のegress（またはVPCエンドポイント）が必要です。

---

## 要件

1. VPC + パブリック/プライベートサブネット + NAT Gateway を構築する
2. API Gateway (HTTP API) が `POST /orders` を order-svc にルーティングする
3. order-svc は注文を RDS に保存し、SNS `orders` に publish する
4. 多段キュー:
   - **processing-svc**: SQS(orders) をトリガーに、S3保存 → Athena分析対象化 → SNS `processed` に publish
   - **notify-svc**: SQS(processed) をトリガーに、通知ログを出力
5. DB認証情報は Secrets Manager で管理し、order-svc が実行時に取得する
6. IAMロールをサービスごとに分離し、最小権限を付与
7. すべてTerraformで構築する

---

## 実装ガイド

- Terraformコード: [examples/terraform/](./examples/terraform/)
- Order Service: [examples/order-svc/](./examples/order-svc/)
- Processing Service: [examples/processing-svc/](./examples/processing-svc/)
- Notify Service: [examples/notify-svc/](./examples/notify-svc/)

### デプロイ手順の概要

```bash
# 1. order-svc は pg(PostgreSQLクライアント) が必要なので依存をインストール
#    （processing-svc / notify-svc は AWS SDK のみ＝ランタイム同梱なので不要）
(cd examples/order-svc && npm install --omit=dev)

# 2. Terraform apply（10〜15分かかる — RDS の作成待ち）
cd examples/terraform
terraform init
terraform apply -var="db_password=ChangeMe1234!"

# 3. RDS にテーブルを作成（初回のみ。下記「テーブル作成」を参照）

# 4. API のURLを取得して注文を送信
API_URL=$(terraform output -raw api_url)
curl -X POST "${API_URL}/orders" \
  -H "Content-Type: application/json" \
  -d '{"customer":"田中太郎","product":"ピザ","amount":2500}'
# レスポンス例: {"message":"Order accepted","order_id":"ORD-1717..."}

# 5. 各サービスのログを確認
aws logs tail /aws/lambda/level3-order-svc --since 5m
aws logs tail /aws/lambda/level3-processing-svc --since 5m
aws logs tail /aws/lambda/level3-notify-svc --since 5m

# 6. 検証完了後は必ず destroy（RDS, NAT は時間課金）
terraform destroy -var="db_password=ChangeMe1234!"
```

### テーブル作成

Terraform が作るのは RDS インスタンスと DB までです。**テーブル作成は別途必要**です。RDSはプライベートなので、踏み台（EC2/SSM）や一時的にパブリック化して接続するか、order-svc に初期化処理を入れます。研修では以下のSQLを流してください。

```sql
CREATE TABLE IF NOT EXISTS orders (
  order_id   TEXT PRIMARY KEY,
  customer   TEXT NOT NULL,
  product    TEXT,
  amount     NUMERIC NOT NULL,
  status     TEXT,
  created_at TIMESTAMPTZ NOT NULL
);
```

### API Gateway (AWS) と GCP API Gateway の比較

| 項目 | AWS API Gateway (HTTP API) | GCP API Gateway |
| --- | --- | --- |
| API定義 | コンソール/Terraform でルート定義 | OpenAPI 2.0 spec をアップロード |
| バックエンド | Lambdaプロキシ統合 / HTTP統合 | `x-google-backend` 拡張 |
| 認証 | IAM, Cognito, Lambda Authorizer, JWT | API Key, Firebase, Google ID Token |
| エンドポイント | `https://{id}.execute-api.{region}.amazonaws.com` | `https://{gw}-{hash}.{region}.gateway.dev` |
| Terraform | `aws_apigatewayv2_*`（GA） | `google-beta`（3リソース構成） |

---

## 完了条件チェックリスト

- [ ] `terraform apply` で全リソースが作成される
- [ ] RDS に `orders` テーブルを作成した
- [ ] API の URL に `curl -X POST .../orders` で注文を送信できる
- [ ] RDS に注文レコードが保存される
- [ ] S3 に加工済みファイルが出力される
- [ ] Athena の `level3_analytics.orders` をSQLでクエリできる
- [ ] notify-svc のログで `processed` メッセージ受信を確認する
- [ ] 各IAMロールが最小権限のみ持つことを確認する
- [ ] **`terraform destroy` で全リソース削除**（RDS, NAT は時間課金）

---

## トラブルシューティング

→ [troubleshooting.md](./troubleshooting.md)

---

## 研修総括

おつかれさまでした！ 2週間でAWSの主要サービスを Terraform で構築するスキルを身につけられたはずです。

実務で次に学ぶといいトピック:

- **CI/CD**: CodePipeline / GitHub Actions による自動デプロイ
- **Observability**: CloudWatch Logs / Metrics / X-Ray
- **Security**: WAF, GuardDuty, AWS Organizations の SCP
- **ECS / EKS**: より複雑なコンテナ基盤
- **Terraform 高度な機能**: dynamic block, workspace, Sentinel/OPA policy
