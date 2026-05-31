# Day 7: データサービス（Pub/Sub・BigQuery・Cloud Functions）

**ゴール**: メッセージキュー（Pub/Sub）とデータウェアハウス（BigQuery）、イベント駆動関数（Cloud Functions）を理解する。

---

## 1. 座学トピック

### Pub/Sub: 非同期メッセージングサービス

```
Publisher → [Topic] → [Subscription] → Subscriber
                          ↓
                     未配信メッセージ
                     をバッファリング
```

| 用語 | 役割 |
| --- | --- |
| **Topic** | メッセージの発行先（配信チャネル） |
| **Subscription** | Topic からメッセージを受け取る購読設定 |
| **Publisher** | Topic にメッセージを送る側 |
| **Subscriber** | Subscription からメッセージを受け取る側 |
| **ack** | Subscriber が「受信完了」を通知すること。ack されないメッセージは再配信される |

#### Push vs Pull

- **Push**: Pub/Sub が指定されたURL（Cloud Run等）にHTTPで通知する
- **Pull**: Subscriber が能動的に Pub/Sub に取りに行く

#### Dead Letter Queue (DLQ)

何度リトライしても処理できないメッセージを「行き止まり」のトピックに退避する仕組み。正常なメッセージの処理を止めずに済む。

AWS で例えると **SNS + SQS** の機能を1サービスでカバーするイメージ。

### BigQuery: サーバーレスデータウェアハウス

- データを保存しつつ、SQLで集計クエリが実行できるサービス
- **データセット**: テーブルをまとめる論理単位（RDBの「スキーマ」に近い）
- **テーブル**: 行と列を持つデータ
- **パーティション**: 日付などでテーブルを物理的に分割。クエリ対象を絞ってコストを下げる
- 課金は「スキャンしたバイト数」と「保存容量」

AWS で例えると **Redshift + Athena** に相当。

### Cloud Functions（第2世代）

- イベントトリガー（GCS, Pub/Sub, Firestore等）またはHTTPトリガーで起動する関数実行環境
- 最大タイムアウト 540秒（9分）
- 第2世代は内部的に Cloud Run の上で動作しており、機能差はほぼなし

AWS で例えると **Lambda** に相当。

---

## 2. ハンズオン

サンプル: [examples/pubsub-bq/](./examples/pubsub-bq/)

### Pub/Sub

```hcl
# Pub/Sub トピック（メッセージの送信先。AWSでいう SNSトピック）
resource "google_pubsub_topic" "orders" {
  name = "orders-topic"
}

# Pub/Sub サブスクリプション（メッセージの受信設定。AWSでいう SQSキュー）
resource "google_pubsub_subscription" "orders_sub" {
  name  = "orders-subscription"
  topic = google_pubsub_topic.orders.id

  ack_deadline_seconds = 20 # メッセージ処理の確認応答までのタイムアウト（秒）
}
```

#### gcloud で動作確認

```bash
# メッセージの publish
gcloud pubsub topics publish orders-topic \
  --message='{"order_id":"ORD-001","customer":"tanaka","amount":1500}'

# メッセージの pull
gcloud pubsub subscriptions pull orders-subscription --auto-ack
```

### BigQuery

```hcl
# BigQuery データセット（テーブルをまとめる論理的な入れ物）
resource "google_bigquery_dataset" "training" {
  dataset_id                  = "training_dataset"
  location                    = var.region
  default_table_expiration_ms = 2592000000 # テーブルの自動削除 = 30日（コスト管理）

  labels = { env = "training" }
}

# BigQuery テーブル
resource "google_bigquery_table" "orders" {
  dataset_id          = google_bigquery_dataset.training.dataset_id
  table_id            = "orders"
  deletion_protection = false # terraform destroy を許可

  # スキーマ定義（JSON形式で列名・型・必須/任意を定義）
  schema = jsonencode([
    { name = "order_id", type = "STRING", mode = "REQUIRED" },
    { name = "customer", type = "STRING", mode = "REQUIRED" },
    { name = "amount", type = "NUMERIC", mode = "REQUIRED" },
    { name = "status", type = "STRING", mode = "NULLABLE" },
    { name = "created_at", type = "TIMESTAMP", mode = "REQUIRED" },
  ])
}
```

#### bq コマンドで動作確認

```bash
# データ挿入（標準SQL）
bq query --use_legacy_sql=false \
  "INSERT INTO training_dataset.orders (order_id, customer, amount, status, created_at)
   VALUES ('ORD-001', 'tanaka', 1500, 'received', CURRENT_TIMESTAMP())"

# 集計クエリ
bq query --use_legacy_sql=false \
  "SELECT status, COUNT(*) AS cnt, SUM(amount) AS total
   FROM training_dataset.orders
   GROUP BY status"
```

---

## 確認課題

1. gcloud CLI で Pub/Sub トピックにメッセージを publish → subscription から pull で受信できること
2. BigQuery コンソールでSQLクエリを実行できること

---

## 補足

- Pub/Sub 設計パターン: [supplementary.md](./supplementary.md)

---

## 次のステップ

→ [Day 8: Level 2 ワークショップ — サーバーレスデータパイプライン](../day08_workshop_level2/README.md)
