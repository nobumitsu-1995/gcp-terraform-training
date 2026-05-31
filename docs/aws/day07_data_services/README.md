# Day 7: データサービス（SNS/SQS・Athena・Lambda）

**ゴール**: メッセージング（SNS/SQS）とデータ分析（Athena）、イベント駆動関数（Lambda）を理解する。

---

## 1. 座学トピック

### SNS / SQS: 非同期メッセージング

GCPの Pub/Sub は「発行/購読」と「キュー」を1サービスで担いますが、AWSでは2つに分かれています。

```
Publisher → [SNS Topic] ──fan-out──┬→ [SQS Queue A] → Worker A
                                   └→ [SQS Queue B] → Worker B
```

| 用語 | 役割 | GCP対応 |
| --- | --- | --- |
| **SNS Topic** | メッセージの発行先（Pub型・配信チャネル） | Pub/Sub Topic |
| **SQS Queue** | メッセージを溜めて1つずつ処理させるキュー | Pub/Sub Subscription |
| **サブスクリプション** | SNS Topic を SQS や Lambda に紐付ける | Subscription |
| **可視性タイムアウト** | 受信中メッセージを他から見えなくする時間。ackされないと再表示 | ack_deadline |
| **DLQ (Dead Letter Queue)** | 何度も失敗したメッセージの退避先 | Dead Letter Topic |

- **SNS**: プッシュ型。複数の購読先に同報（fan-out）する
- **SQS**: プル型。1つのワーカーが順に処理する（負荷平準化・リトライ）
- **組み合わせ**: 「SNS → 複数SQS」で、Pub/Subのような疎結合な多段配信を作る

### Athena: サーバーレスSQL分析

- S3上のデータ（JSON/CSV/Parquet）に対して、サーバー不要でSQLを実行できる
- スキーマは **Glue データカタログ** に定義する（データベース・テーブル）
- 課金は「スキャンしたデータ量」（$5 / TB）。パーティションで対象を絞るとコスト減
- GCP で例えると **BigQuery（特にサーバーレスなクエリ実行）** に相当。大規模DWHが必要なら Redshift

### Lambda: サーバーレス関数

- イベントトリガー（S3, SQS, SNS, EventBridge等）またはHTTP（API Gateway / Function URL）で起動
- 最大タイムアウト 15分、従量課金（100万リクエスト/月まで常時無料）
- GCP で例えると **Cloud Functions** に相当

SQSをトリガーにするLambdaの例:

```javascript
// SQSからのメッセージを処理するLambdaハンドラ
exports.handler = async (event) => {
  for (const record of event.Records) {
    const body = JSON.parse(record.body);
    console.log("Received:", body);
    // ここで集計・S3書き込み・DB保存などを行う
  }
  return { statusCode: 200 };
};
```

---

## 2. ハンズオン

サンプル: [examples/messaging-athena/](./examples/messaging-athena/)

### SNS → SQS

```hcl
resource "aws_sns_topic" "events" {
  name = "events-topic"
}

resource "aws_sqs_queue" "events" {
  name = "events-queue"
}

# SNS → SQS のサブスクリプション
resource "aws_sns_topic_subscription" "events" {
  topic_arn = aws_sns_topic.events.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.events.arn
}
```

#### AWS CLI で動作確認

```bash
cd examples/messaging-athena
terraform init
terraform apply

# SNS にメッセージを publish
aws sns publish \
  --topic-arn "$(terraform output -raw topic_arn)" \
  --message '{"name":"click","value":1}'

# SQS から受信
aws sqs receive-message --queue-url "$(terraform output -raw queue_url)"
```

### Athena（S3 + Glue）

```bash
# 分析対象のJSONをデータ用バケットに置く
echo '{"name":"click","value":1,"received_at":"2026-01-01T00:00:00Z"}' > event.json
aws s3 cp event.json "s3://$(terraform output -raw data_bucket)/"

# Athena でクエリ実行
aws athena start-query-execution \
  --query-string "SELECT name, COUNT(*) AS cnt FROM events_db.events GROUP BY name" \
  --work-group events-workgroup
```

---

## 確認課題

1. SNS にメッセージを publish → SQS から受信できること。
2. データ用S3にJSONを置き、Athena でクエリできること。
3. **後片付け**: `terraform destroy`。

---

## 補足

- メッセージング設計パターン: [supplementary.md](./supplementary.md)

---

## 次のステップ

→ [Day 8: Level 2 ワークショップ — サーバーレスデータパイプライン](../day08_workshop_level2/README.md)
