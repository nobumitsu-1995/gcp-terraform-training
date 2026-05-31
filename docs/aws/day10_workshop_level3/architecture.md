# Level 3 アーキテクチャ詳細

## システム全体フロー

```
[User]
  │ HTTPS
  ▼
[API Gateway (HTTP API)]            ← POST /orders, GET /health
  │ Lambdaプロキシ統合
  ▼
[order-svc (Lambda, VPC内)]
  │
  ├─ INSERT ──────────────▶ [RDS PostgreSQL] ← プライベートサブネット
  │                                ↑
  │                    [Secrets Manager: db-password]（実行時に取得）
  │
  └─ publish ──▶ [SNS: orders]
                      │ subscription
                      ▼
                 [SQS: orders-queue]
                      │ event source mapping
                      ▼
                 [processing-svc (Lambda)]
                      │
                      ├─ write ─▶ [S3: processed] ──▶ Athena (Glue)
                      │
                      └─ publish ──▶ [SNS: processed]
                                          │ subscription
                                          ▼
                                     [SQS: notify-queue]
                                          │ event source mapping
                                          ▼
                                     [notify-svc (Lambda)]
                                          │
                                          └─ log only
```

## 各コンポーネントの役割

### API Gateway (HTTP API)

- `POST /orders` / `GET /orders` / `GET /health` を order-svc にプロキシ統合
- `aws_lambda_permission` で API Gateway からの Lambda 呼び出しを許可

### order-svc (Lambda, VPC内)

- **責務**: HTTP受付 / バリデーション / RDS保存 / SNS publish
- **VPC配置**: RDS（プライベート）に接続するため private subnet に配置
- **Secrets Manager**: DBパスワードを環境変数に平文で置かず、実行時に取得
- ユーザーには 202 Accepted を即座に返す

### SNS orders → SQS orders-queue

- SNS が発行/購読、SQS がバッファリングとリトライを担当
- processing-svc は SQS の event source mapping で起動

### processing-svc (Lambda)

- **責務**: 加工 / S3保存 / Athena分析対象化 / SNS `processed` へ publish
- VPC外で動作（S3・SNS・Athena はパブリックAWS API のため）

### SNS processed → SQS notify-queue → notify-svc

- 完了通知の伝播。notify-svc はログ出力のみ（本番では SES/SNS(SMS)/Slack）

## サービスアカウント（IAMロール）と権限マトリクス

| ロール | 主な権限 |
| --- | --- |
| `level3-order-svc-role` | VPCアクセス, `secretsmanager:GetSecretValue`(対象secret), `sns:Publish`(orders) |
| `level3-processing-svc-role` | SQS実行, `s3:PutObject`(processed), `sns:Publish`(processed) |
| `level3-notify-svc-role` | SQS実行, ログ書き込みのみ |

**最小権限の原則**: 各サービスは自分が必要とする権限だけを持つ。例えば order-svc は S3 への書き込み権限を持たない。

## ネットワーク構成

```
VPC 10.0.0.0/16
├── public  10.0.101.0/24, 10.0.102.0/24  (IGW + NAT Gateway)
└── private 10.0.1.0/24,  10.0.2.0/24     (order-svc Lambda, RDS)
```

- order-svc Lambda は private subnet。SNS/Secrets Manager への egress は NAT Gateway 経由
- RDS は private subnet、Lambda SG からの 5432 のみ許可

## 課金注意リソース

| リソース | 課金単位 | 時間あたり目安 |
| --- | --- | --- |
| RDS (db.t3.micro) | 時間課金 | $0.017（無料枠超過時） |
| NAT Gateway | 時間 + データ処理 | $0.045 + 転送量 |
| Secrets Manager | シークレット数 | $0.40 / 月 |
| API Gateway | 従量 | $1 / 100万リクエスト |
| Lambda / SNS / SQS / S3 / Athena | 従量 | ほぼ無料枠 |

**1時間稼働で $0.06〜0.10 程度**。確認後は必ず `terraform destroy` で停止すること。
