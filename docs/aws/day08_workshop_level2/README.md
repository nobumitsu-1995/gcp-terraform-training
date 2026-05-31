# Day 8: Level 2 ワークショップ — サーバーレスデータパイプライン

## ビジネスシナリオ

> **シチュエーション**: あなたはEコマース企業のデータ基盤チームにいます。サイトの注文イベントを受け取り、データ基盤に蓄積して分析できるようにしたいという要望があります。さらに、生イベントはあとから再処理できるようアーカイブしておきたい。
>
> **あなたの課題**: 注文イベントを受け取るAPI（Lambda Function URL）→ SNS/SQSでメッセージング → イベント処理（Lambda）→ S3に蓄積（Athenaで分析）、というサーバーレスデータパイプラインをTerraformで構築してください。

## 課題構成図

詳細は [architecture.md](./architecture.md) を参照。

```
[クライアント]
    │ POST (注文JSON)
    ▼
[Lambda: order-api (Function URL)]
    │ publish
    ▼
[SNS: orders-topic]
    │ subscription
    ▼
[SQS: orders-process-queue]
    │ event source mapping
    ▼
[Lambda: process-order] ──┬─→ [S3: data バケット (orders/*.json)] ──▶ Athena で分析
                          └─→ [S3: raw-events バケット (生データ保管)]
```

---

## 使用するAWSサービス

| AWSサービス | 役割 | GCPでの対応 |
| --- | --- | --- |
| Lambda (Function URL) | 注文受付API（HTTPエンドポイント） | Cloud Run |
| SNS + SQS | イベントメッセージング | Pub/Sub |
| Lambda | イベント処理・S3書き込み | Cloud Functions |
| S3 + Athena (Glue) | データ蓄積・分析 | BigQuery |
| S3 | 生イベントのアーカイブ | Cloud Storage |

> 💡 GCPでは注文受付APIをコンテナ（Cloud Run）で作りましたが、ここでは**Lambda Function URL**でHTTPエンドポイントを払い出します。コンテナで作りたい場合は Day 6 の App Runner に差し替え可能です。

---

## 要件

1. **order-api (Lambda Function URL)**: 注文JSONを受け取り、SNSにpublishする
2. **orders-topic (SNS)**: 注文イベントのトピック
3. **orders-process-queue (SQS)**: SNSから受信し、処理Lambdaへ渡すキュー
4. **process-order (Lambda)**: SQSをトリガーに、注文データをS3（Athena用）に書き込み、生データもアーカイブ
5. **Athena (Glue)**: `ecommerce.orders` テーブルでS3上のデータをSQL分析
6. すべてTerraformで構築する

---

## 実装のヒント

### order-api (Lambda) の役割

注文JSONを受け取り、SNS にpublishする軽量なAPI。詳細は [examples/order-api/index.js](./examples/order-api/index.js) を参照。AWS SDK は Lambda ランタイムに同梱されているため `node_modules` は不要です。

### process-order (Lambda) の役割

SQSメッセージ（SNS通知でラップされている）をデコードし、S3に書き込む。詳細は [examples/processor/index.js](./examples/processor/index.js) を参照。

### Terraform構成

```
examples/terraform/
├── terraform.tf      # provider, バージョン制約
├── messaging.tf      # SNSトピック・SQSキュー・サブスクリプション・トリガー
├── order_api.tf      # 注文受付API (Lambda + Function URL)
├── processor.tf      # イベント処理関数 (Lambda)
├── athena.tf         # Glueデータベース・テーブル・Athenaワークグループ
├── storage.tf        # データ用・アーカイブ用バケット
├── iam.tf            # IAMロール・権限
└── outputs.tf        # 出力値
```

### 実行手順

```bash
cd examples/terraform
terraform init
terraform apply

# 注文を投入
curl -X POST "$(terraform output -raw order_api_url)" \
  -H "Content-Type: application/json" \
  -d '{"order_id":"ORD-123","customer":"tanaka","amount":15000,"items":["item-A","item-B"]}'

# S3にデータが入ったか確認
aws s3 ls "s3://$(terraform output -raw data_bucket)/orders/"

# Athena で分析
aws athena start-query-execution \
  --query-string "SELECT customer, SUM(amount) FROM ecommerce.orders GROUP BY customer" \
  --work-group level2-workgroup
```

---

## 完了条件チェックリスト

- [ ] `terraform apply` で全リソースが作成される
- [ ] order-api に注文JSONをPOSTできる
- [ ] S3の `orders/` に処理済みデータが入る
- [ ] raw-events バケットに生イベントがアーカイブされる
- [ ] Athena の `ecommerce.orders` をSQLでクエリできる
- [ ] **`terraform destroy` で全リソース削除**

---

## 次のステップ

→ [Day 9: ネットワーク・DB・セキュリティ](../day09_network_security/README.md)
