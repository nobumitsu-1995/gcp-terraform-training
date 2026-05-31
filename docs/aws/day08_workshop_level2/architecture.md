# Level 2 アーキテクチャ詳細

## データフロー

```
1. クライアントが order-api (Lambda Function URL) に POST
   {
     "order_id": "ORD-123",
     "customer": "tanaka",
     "amount": 15000,
     "items": ["item-A", "item-B"]
   }

2. order-api が SNS の orders-topic に publish

3. SNS → SQS (orders-process-queue) にサブスクリプション経由で配信

4. SQS の event source mapping が process-order Lambda を起動
   ├─ 処理済みレコードを data バケット (orders/ORD-123.json) に保存
   └─ 生イベントを raw-events バケットにアーカイブ

5. アナリストが Athena で ecommerce.orders を SQL 分析
```

## コンポーネント詳細

### order-api (Lambda + Function URL)

- Function URL でHTTPエンドポイントを払い出す（API Gateway不要の軽量構成）
- 注文を受け取り、バリデーション後 SNS に publish
- レスポンスは即座に返す（非同期処理）

### orders-topic (SNS) → orders-process-queue (SQS)

- SNS は発行/購読（fan-out）を担い、SQS はメッセージのバッファリングとリトライを担う
- **fan-out 拡張**: SNSにSQSをもう1つ subscribe させれば、通知用・監査用など別系統を疎結合に追加できる
- SQS → SNS の場合、SQSの `body` は SNS通知のJSONで、元のペイロードは `body.Message` に入る

### process-order (Lambda)

- SQS の event source mapping で起動（バッチで複数メッセージを処理）
- メッセージをデコードし、S3に保存
- エラー時はSQSの可視性タイムアウト経過後に再配信（リトライ）

### S3 + Athena

- `data` バケットの `orders/` 配下に1注文1JSONで保存
- Glue データベース `ecommerce` とテーブル `orders` がスキーマを定義
- Athena がS3上のJSONを直接SQLでクエリ

### S3（アーカイブ）

- 生のイベントJSONをそのまま `raw-events` バケットに保管
- ライフサイクルで90日後に自動削除

## セキュリティ設計

- 各Lambdaは専用のIAMロールで動作
- order-api → SNS: `sns:Publish` のみ
- process-order → SQS受信 + S3書き込み (`s3:PutObject`) のみ
- 最小権限の原則を徹底

## コスト注意点

| サービス | 無料枠 | 備考 |
| --- | --- | --- |
| Lambda | 100万リクエスト/月 | ほぼ無料 |
| SNS / SQS | 各100万リクエスト/月 | ほぼ無料 |
| S3 | 5GB/月（12ヶ月） | ほぼ無料 |
| Athena | $5/TBスキャン | 数MBなら実質$0 |

> 💡 Level 2 は全体的に無料枠に収まりやすい構成。ただし放置すると塵も積もるので destroy は忘れずに。
