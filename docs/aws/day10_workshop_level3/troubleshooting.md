# Day 10 トラブルシューティング集

研修全体で発生しがちな問題と対処法をまとめます。

---

## Terraform 関連

### `terraform apply` がタイムアウトする

RDS の作成には10〜15分かかることがあります。気長に待ってください。タイムアウトを延ばすには:

```hcl
resource "aws_db_instance" "main" {
  # ...
  timeouts {
    create = "40m"
  }
}
```

### `terraform destroy` が失敗する

- RDS の `deletion_protection = false`、`skip_final_snapshot = true` を確認
- S3 バケットの `force_destroy = true` を確認
- Secrets Manager は `recovery_window_in_days = 0` でないと即削除されない（同名再作成でぶつかる）

### state lock が解除されない

別の人（または別ターミナル）が apply 中です。完了を待つか、緊急時は:

```bash
terraform force-unlock LOCK_ID
```

---

## API Gateway 関連

### 403 / 404 が返る

- ルート（`POST /orders` 等）が定義されているか確認
- `aws_lambda_permission` で API Gateway からの呼び出しが許可されているか
- ステージ（`$default`）が `auto_deploy = true` でデプロイされているか

### Lambdaプロキシ統合でレスポンスがおかしい

HTTP API (payload v2.0) のレスポンスは `{ statusCode, headers, body }` 形式で返す必要があります。`body` は文字列（JSONは `JSON.stringify`）。

---

## Lambda 関連

### order-svc が `Cannot find module 'pg'`

`pg` は Lambda ランタイムに含まれません。デプロイ前に依存をインストールしてください:

```bash
cd examples/order-svc && npm install --omit=dev
```

`archive_file` が `node_modules` ごとZIP化します。

### VPC内Lambdaがタイムアウトする（SNS/Secrets Managerに繋がらない）

VPC内のLambdaはデフォルトでインターネットに出られません。SNS・Secrets Manager はパブリックAWS APIなので、以下のいずれかが必要です:

- **NAT Gateway 経由のegress**（本ワークショップの構成）
- **VPCインターフェースエンドポイント**（NATなしでAWS APIに到達。コスト最適化向き）

```hcl
# 例: SNS の VPCエンドポイント（NATの代替）
resource "aws_vpc_endpoint" "sns" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.sns"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.lambda.id]
  private_dns_enabled = true
}
```

### Apple Silicon Mac での注意

Lambda は zip デプロイ（このワークショップの方式）なら、Node.js コードはアーキテクチャ非依存なので問題ありません。ネイティブモジュールを含む場合のみ注意が必要です。

---

## RDS 関連

### order-svc から RDS に接続できない

- order-svc Lambda が RDS と同じ VPC・適切なサブネットに配置されているか（`vpc_config`）
- RDS のセキュリティグループが Lambda の SG からの 5432 を許可しているか
- `DB_HOST` が RDS のエンドポイント（`aws_db_instance.main.address`）になっているか

### `relation "orders" does not exist`

Terraform は RDS インスタンスと DB までしか作りません。**テーブル作成は別途必要**です（READMEの「テーブル作成」参照）。

---

## SNS / SQS 関連

### メッセージが processing-svc に届かない

- SNS → SQS のサブスクリプションが作成されているか
- SQS のキューポリシーで SNS からの `sqs:SendMessage` が許可されているか
- Lambda の event source mapping が有効か
- SQS の `body` は SNS通知のJSON。元データは `JSON.parse(record.body).Message` に入っている

### メッセージが何度も再処理される

Lambda がエラーを返すと SQS が可視性タイムアウト後に再配信します。可視性タイムアウトは **Lambdaタイムアウトの6倍以上**を推奨。繰り返し失敗するメッセージは DLQ に退避しましょう。

---

## 認証関連

### `AccessDenied` / `not authorized to perform`

該当の IAM ロールに必要なアクションが付与されていません。最小権限の各ポリシー（`iam.tf`）を確認してください。

---

## 参考リンク

- Terraform AWS Provider: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- API Gateway (HTTP API): https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api.html
- Lambda: https://docs.aws.amazon.com/lambda/latest/dg/
- SNS: https://docs.aws.amazon.com/sns/latest/dg/
- SQS: https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/
- RDS: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/
- Athena: https://docs.aws.amazon.com/athena/latest/ug/
