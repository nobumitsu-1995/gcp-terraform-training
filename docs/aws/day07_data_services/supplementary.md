# Day 7 補足: メッセージング設計パターン

## 1. Fan-out（1対多配信）

SNS Topic に複数の SQS Queue を subscribe させると、全員に同じメッセージが届きます。

```
                ┌─ SQS Queue A → Notify Worker
Publisher → SNS ─┼─ SQS Queue B → Analytics Worker
                └─ SQS Queue C → Audit Worker
```

購読先を追加してもPublisher側を変更しなくて済む、疎結合な設計です。

## 2. 多段パイプライン

```
SNS A → SQS → Lambda → SNS B → SQS → Lambda B
```

処理を段階に分け、各段が独立してスケール・リトライできます。Day 8 / Day 10 で実装します。

## 3. Dead Letter Queue (DLQ)

```hcl
resource "aws_sqs_queue" "dlq" {
  name = "events-dlq"
}

resource "aws_sqs_queue" "events" {
  name = "events-queue"

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 5 # 5回処理に失敗したらDLQへ
  })
}
```

## 4. 可視性タイムアウト (visibility timeout)

メッセージ処理にかかる最大時間より長く設定すること。短いと「処理中なのに再配信される」事故が起きます。

| 処理内容の例 | 推奨 visibility timeout |
| --- | --- |
| メール送信、シンプルなDB書き込み | 30秒 |
| 画像処理、外部API呼び出し | 60〜120秒 |
| 大きなETL | 300〜900秒 |

> 💡 SQSトリガーのLambdaでは、キューの可視性タイムアウトを **Lambdaタイムアウトの6倍以上** にするのが推奨です。

## 5. FIFO キューで順序保証

```hcl
resource "aws_sqs_queue" "orders" {
  name                        = "orders.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
}
```

`.fifo` サフィックスが必須。順序とexactly-onceを保証しますが、スループット上限が下がります。

## 6. Athena のコスト最適化

- **パーティション**: `year/month/day` でS3を分割し、`WHERE` で対象を絞る
- **列指向フォーマット (Parquet)**: スキャン量が激減する
- **圧縮**: gzip/snappy でストレージとスキャン量を削減

```sql
-- パーティション射影でスキャン量を絞る
SELECT * FROM events WHERE year='2026' AND month='01';
```

## 7. EventBridge という選択肢

イベントのルーティング・フィルタリングが複雑なら EventBridge（旧 CloudWatch Events）を使います。SaaS連携やスケジュール実行（cron）にも対応します。
