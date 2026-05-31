# Day 10: Level 3 ワークショップ — マイクロサービス基盤

**GCP API Gateway + Cloud Run + Pub/Sub多段キュー + Cloud SQL**

## ビジネスシナリオ

> **シチュエーション**: あなたは急成長中のフードデリバリーサービス「QuickBite」のバックエンド開発チームに所属しています。これまでモノリシックなアプリケーションで運用していましたが、注文数が急増し、以下の問題が発生しています:
>
> - 注文処理が集中するとレスポンスが悪化する
> - 決済処理の障害が通知機能まで巻き込んでサービス全体が停止する
> - 新機能のデプロイが全サービスの再デプロイを必要とし、リリースサイクルが遅い
>
> CTOから「マイクロサービスアーキテクチャに移行して、各サービスを独立してスケール・デプロイできるようにしたい。APIの入口はOpenAPI specで定義して、GCP API Gatewayで認証・ルーティング・レート制限を一元管理したい。サービス間の通信はメッセージキューで疎結合にして障害の伝播を防ぎたい」という方針が出ました。
>
> **あなたの課題**: GCP API Gatewayで外部リクエストを受け、OpenAPI specに基づいてCloud Runの各マイクロサービスにルーティングする注文処理基盤をTerraformで構築してください。

## 課題構成図

![Level 3 構成図](./architecture.png)

詳細解説は [architecture.md](./architecture.md) を参照。

```
User → GCP API Gateway（OpenAPI spec）
         → Order Svc（Cloud Run）→ Cloud SQL + Pub/Sub `orders`
             → Processing Svc → GCS + BigQuery + Pub/Sub `processed`
                 → Notify Svc
```

---

## 使用するGCPサービスと役割

| GCPサービス            | 役割                                   | AWSでの対応サービス | コスト注意                     |
| ---------------------- | -------------------------------------- | ------------------- | ------------------------------ |
| GCP API Gateway        | OpenAPI specベースのルーティング・認証 | Amazon API Gateway  | 従量課金（$3/100万リクエスト） |
| Cloud Run × 3サービス  | Order, Processing, Notify              | ECS Fargate         | ゼロスケールで無料枠内         |
| Pub/Sub × 2トピック    | orders / processed キュー              | SNS + SQS           | 無料枠内                       |
| Cloud SQL (PostgreSQL) | 注文データRDB                          | RDS                 | **時間課金。db-f1-micro推奨**  |
| Cloud Storage (GCS)    | 加工済みファイル保存                   | S3                  | 無料枠内                       |
| BigQuery               | 分析用データウェアハウス               | Redshift / Athena   | 無料枠内                       |
| Artifact Registry      | コンテナイメージ管理                   | ECR                 | 無料枠内                       |
| VPC + VPCコネクタ      | Cloud Run → Cloud SQL 接続             | VPC + NAT GW        | **VPCコネクタは時間課金**      |
| Secret Manager         | DB認証情報                             | Secrets Manager     | 無料枠内                       |
| IAM + Service Account  | サービス間認証・認可                   | IAM Role            | 無料                           |

---

## なぜこの構成なのか

### 「なぜモノリスを3つのCloud Runサービスに分けるのか」

QuickBiteの現状の問題を振り返ると:

- 注文処理が集中するとレスポンスが悪化する → **注文受付と後続処理を分離すれば、受付のレスポンスは即座に返せる**
- 決済処理の障害が通知まで巻き込む → **サービスが分かれていれば、Processing Svcが落ちてもOrder SvcとNotify Svcは影響を受けない**
- 新機能のデプロイが全体の再デプロイを要する → **サービスごとに独立してデプロイ・スケールできる**

具体的には:

- **Order Svc** はユーザーに直接レスポンスを返すサービスなので、低レイテンシが求められます。DB保存とPub/Sub publishだけに絞り、重い処理は後続に委譲します
- **Processing Svc** はCPU・メモリを多く使うデータ加工処理を担当します。Order Svcとは独立してスケールでき、重い処理に合わせてリソースを増やせます
- **Notify Svc** は通知という独立した関心事を持ちます。将来メール/SMS/Pushなど通知手段が増えても、このサービスだけを拡張すればよくなります

ただし、分けすぎると運用負荷が上がるため「1つのチームが所有・運用できる単位で分ける」のが実務上の目安です。

### 「なぜOrder SvcからProcessing Svcを直接HTTPで呼ばず、Pub/Subを挟むのか」

```
× 同期呼び出し（密結合）:
  User → API GW → Order Svc → Processing Svc → Notify Svc → User
  問題: Processing Svcが3秒かかるとユーザーが3秒待つ。障害が全体に波及する。

○ Pub/Sub経由（疎結合）:
  User → API GW → Order Svc → 202 Accepted（即座に返す）
                       ↓ (非同期)
                   Pub/Sub orders → Processing Svc → Pub/Sub processed → Notify Svc
  利点: ユーザーは待たない。各サービスが独立して動く。
```

Pub/Sub を挟むことで:

- **ユーザーへのレスポンスが高速**: Order Svcは「受け付けました」を即座に返し、重い処理はバックグラウンドで実行されます
- **障害の隔離**: Processing Svcがダウンしても注文受付は止まりません
- **スケールの独立**: 注文が急増してもOrder Svcだけスケールアウトすれば受付は維持でき、Processing Svcは自分のペースで処理を消化します
- **fan-out**: 1つのメッセージを複数のサブスクリプションに同時配信でき、新しいサービスの追加が既存サービスに影響しません

### 「なぜPub/Subトピックを2つに分けるのか（多段キュー）」

`orders` と `processed` の2つに分けることで、処理フローの段階ごとに異なるサブスクライバーを設定できます:

- `orders` トピック: Processing Svc が購読。将来「在庫管理Svc」を追加する場合も、このトピックにサブスクリプションを追加するだけ（Order Svc の変更は不要）
- `processed` トピック: Notify Svc が購読。将来「分析Svc」や「ポイント付与Svc」を追加する場合も同様

もし1つのトピックだけで全部やると、Notify Svc が注文生データと処理完了データを区別するロジックを持つ必要があり、各サービスの責務が曖昧になります。

### 「なぜAPI GatewayをCloud Runで自作せず、GCP API Gatewayサービスを使うのか」

Cloud Run で Express アプリを書いてルーティングすることも技術的には可能ですが:

- **認証・レート制限がゼロコードで手に入る**: GCP API Gateway は OpenAPI spec に設定を書くだけで、APIキー認証やレート制限が有効になります
- **OpenAPI spec がドキュメントとして機能する**: API の仕様がコード（spec）として管理されるため、バックエンドの実装と API の契約が分離されます
- **運用負荷がゼロ**: フルマネージドなのでインスタンス管理やスケーリングの設定が不要
- **バックエンドの差し替えが容易**: spec の `x-google-backend` を書き換えるだけで、バックエンドを Cloud Run から Cloud Functions や GKE に切り替えられます

### 「VPCコネクタは何のために必要なのか」

Cloud Run はサーバーレスのため、デフォルトでは Google のマネージド環境で動作し、自分の VPC にはアクセスできません。Cloud SQL をセキュリティのためにプライベートIPのみ（パブリックIP無効）にしている場合、Cloud Run から Cloud SQL に接続するには「サーバーレス VPC コネクタ」という橋渡しが必要です。

---

## 要件

1. VPC + サブネット + サーバーレスVPCコネクタを構築する
2. OpenAPI 2.0 specを作成し、GCP API Gateway でルーティング・認証を定義する
3. API Gateway が `POST /orders` を Order Svc（Cloud Run）にルーティングする
4. Order Svc は注文を Cloud SQL に保存し、Pub/Sub `orders` トピックに publish する
5. 2つのCloud Runサービスが非同期で処理する:
   - **Processing Svc**: `orders` トピックを subscribe し、データ加工→GCS保存→BigQueryロード→`processed` トピックに publish
   - **Notify Svc**: `processed` トピックを subscribe し、配達員・顧客への通知ログを出力
6. 多段キュー: Order Svc → `orders` → Processing Svc → `processed` → Notify Svc
7. コンテナイメージは Artifact Registry で管理
8. サービスアカウントをサービスごとに分離し、最小権限を付与
9. DB認証情報は Secret Manager で管理
10. すべてTerraformで構築する

---

## 実装ガイド

- Terraformコード: [examples/terraform/](./examples/terraform/)
- OpenAPI spec: [examples/terraform/openapi.yaml](./examples/terraform/openapi.yaml)
- Order Service: [examples/order-svc/](./examples/order-svc/)
- Processing Service: [examples/processing-svc/](./examples/processing-svc/)
- Notify Service: [examples/notify-svc/](./examples/notify-svc/)

### デプロイ手順の概要

```bash
# --- 事前準備 ---
# 1. 環境変数を設定
export TF_VAR_project_id=$GOOGLE_CLOUD_PROJECT

# 2. 3つのサービスをビルド & プッシュ
# (Day6, Day8で作成したリポジトリを再利用します)
gcloud auth configure-docker asia-northeast1-docker.pkg.dev
for svc in order-svc processing-svc notify-svc; do
  (cd docs/gcp/day10_workshop_level3/examples/${svc} \
   && docker build -t asia-northeast1-docker.pkg.dev/${GOOGLE_CLOUD_PROJECT}/training-repo/${svc}:v1 . \
   && docker push   asia-northeast1-docker.pkg.dev/${GOOGLE_CLOUD_PROJECT}/training-repo/${svc}:v1)
done

# --- Terraform デプロイ ---
# 3. Terraform apply（10〜15分かかります — Cloud SQL の作成待ち）
cd docs/gcp/day10_workshop_level3/examples/terraform
terraform init
terraform apply

# --- 動作確認 ---
# 4. API Gateway の URL を取得
GW_URL=$(terraform output -raw api_gateway_url)

# 5. 注文を送信
curl -X POST "${GW_URL}/orders" \
  -H "Content-Type: application/json" \
  -d '{"customer":"田中太郎","product":"ピザ","amount":2500}'

# レスポンス例: {"message":"Order accepted","order_id":"ORD-1717..."}

# 6. Cloud Run のログで各サービスが順に動いていることを確認
gcloud run services logs read order-svc      --region=asia-northeast1 --limit=20
gcloud run services logs read processing-svc --region=asia-northeast1 --limit=20
gcloud run services logs read notify-svc     --region=asia-northeast1 --limit=20

# --- 後片付け ---
# 7. 検証完了後は必ず destroy（Cloud SQL は時間課金）
terraform destroy
```

### GCP API Gateway の3層構造

```
google_api_gateway_api (論理的なAPI)
    │
    ├── google_api_gateway_api_config (OpenAPI spec)
    │      ↑ 不変。変更時は新規作成 → 切り替え
    │
    └── google_api_gateway_gateway (実エンドポイント)
           ↑ api_config を参照
```

`google_api_gateway_api_config` は **不変リソース**（OpenAPI spec の変更で再作成される）のため、`lifecycle { create_before_destroy = true }` を必ず指定してダウンタイムを防ぎます。

### AWS API Gateway との比較

| 項目             | GCP API Gateway                                    | AWS API Gateway                                       |
| ---------------- | -------------------------------------------------- | ----------------------------------------------------- |
| API定義          | OpenAPI 2.0（Swagger）spec をアップロード          | OpenAPI 3.0 or コンソール/CDKで定義                   |
| バックエンド指定 | `x-google-backend` 拡張フィールド                  | Lambda統合 / HTTP統合 / VPCリンク                     |
| 認証             | API Key, Firebase Auth, Google ID Token, SA        | IAM, Cognito, Lambda Authorizer                       |
| エンドポイント   | `https://{gateway-id}-{hash}.{region}.gateway.dev` | `https://{api-id}.execute-api.{region}.amazonaws.com` |
| 課金             | $3/100万リクエスト + データ転送                    | $1〜3.5/100万リクエスト（REST/HTTP）                  |
| Terraform        | `google-beta` プロバイダ（3リソース構成）          | `aws_apigatewayv2_api`（GA）                          |

---

## 完了条件チェックリスト

- [ ] `terraform plan` がエラーなく通る
- [ ] `terraform apply` で全リソース作成
- [ ] API Gateway の URL に `curl -X POST .../orders` で注文を送信できる
- [ ] Cloud SQL に注文レコードが保存される
- [ ] GCS に加工済みファイルが出力される
- [ ] BigQuery テーブルにデータがロードされる
- [ ] Cloud Run ログで Notify Svc が `processed` メッセージを受信していることを確認する
- [ ] 各サービスアカウントが最小権限のロールのみ持っていることを確認する
- [ ] **`terraform destroy` で全リソース削除**（Cloud SQL, VPCコネクタは時間課金）

---

## トラブルシューティング

→ [troubleshooting.md](./troubleshooting.md)

---

## 研修総括

おつかれさまでした！ 2週間でGCPの主要サービスを Terraform で構築するスキルを身につけられたはずです。

実務で次に学ぶといいトピック:

- **CI/CD**: Cloud Build / GitHub Actions による自動デプロイ
- **Observability**: Cloud Logging / Cloud Monitoring / Cloud Trace
- **Security**: Cloud Armor, VPC Service Controls, Workload Identity
- **GKE**: 大規模マイクロサービスにはKubernetesが必要になることも
- **Terraform 高度な機能**: dynamic block, workspace, sentinel policy
