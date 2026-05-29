# Day 7 補足: Pub/Sub 設計パターン

## 1. Fan-out（1対多配信）

1つのトピックに対して複数のサブスクリプションを作ると、全員に同じメッセージが配信されます。

```
                ┌─ Subscription A → Notify Svc
Publisher → Topic ─┼─ Subscription B → Analytics Svc
                └─ Subscription C → Audit Svc
```

新しい購読者を追加するときに、Publisher 側を変更する必要がない疎結合な設計です。

## 2. 多段キュー（パイプライン）

```
Topic A → Subscription → Service → publish → Topic B → Subscription → Service B
```

処理を段階に分け、それぞれが独立してスケール・リトライできます。Day 8 / Day 10 のワークショップで実装します。

## 3. Dead Letter Topic (DLQ)

```hcl
resource "google_pubsub_topic" "dlq" {
  name = "orders-dlq"
}

resource "google_pubsub_subscription" "orders_sub" {
  name  = "orders-sub"
  topic = google_pubsub_topic.orders.id

  ack_deadline_seconds = 60

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.dlq.id
    max_delivery_attempts = 5 # 5回失敗したらDLQへ
  }

  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }
}
```

## 4. ack_deadline_seconds の決め方

メッセージ処理にかかる最大時間より長く設定すること。短いと「処理中なのに再配信される」事故が起きる。

| 処理内容の例 | 推奨 ack_deadline |
| --- | --- |
| メール送信、シンプルなDB書き込み | 10〜30秒 |
| 画像処理、外部API呼び出し | 60〜120秒 |
| 大きなCSVのETL | 300〜600秒 |

> 💡 ack_deadline の上限は 600 秒。それ以上かかる処理は別途 `modifyAckDeadline` を呼んで延長するか、処理を非同期化する。

## 5. 順序保証（Ordering）

```hcl
resource "google_pubsub_topic" "orders" {
  name = "orders"
}

resource "google_pubsub_subscription" "orders_sub" {
  name                = "orders-sub"
  topic               = google_pubsub_topic.orders.id
  enable_message_ordering = true   # 順序保証を有効化
}
```

Publisher 側で `ordering_key` を指定したメッセージは、同じキー内で順番が保証されます。**ただしスループットが大幅に下がる** ので必要な場面以外では使わないこと。

## 6. BigQuery Subscription（直接ロード）

Pub/Sub → BigQuery を Cloud Run 等を介さず直接連携する機能。データパイプラインを単純にできます。

```hcl
resource "google_pubsub_subscription" "to_bq" {
  name  = "orders-to-bq"
  topic = google_pubsub_topic.orders.id

  bigquery_config {
    table          = "${var.project_id}.training_dataset.orders"
    write_metadata = true
    use_topic_schema = true
  }
}
```

シンプルな取り込みであれば Cloud Functions / Cloud Run を挟まずに済みます。
