# AWS + Terraform ワークショップ研修資料

**対象者**: インフラ・AWS未経験者（macOS環境）
**期間**: 2週間（Day 0 準備 + 10営業日）
**形式**: 座学 → ハンズオン → ワークショップ（構成図をTerraformで実装）

> 📚 GCP版の講座は [../gcp/README.md](../gcp/README.md) にあります。同じカリキュラム構成なので、両方を読むと両クラウドの対応関係が理解できます。

---

## ディレクトリ構成

```
docs/aws/
├── README.md                          ← このファイル（AWS講座の目次・スケジュール・コスト設計）
├── day00_setup/                       環境準備（AWSアカウント・AWS CLI・Terraform）
├── day01_cloud_basics/                クラウドとAWSの基礎概念
├── day02_awscli/                      AWSコンソール操作・AWS CLI
├── day03_terraform_intro/             Terraform入門
├── day04_terraform_practice/          Terraform実践パターン
├── day05_workshop_level1/             Level 1 ワークショップ（S3 + CloudFront）
├── day06_container/                   コンテナ基礎・App Runner / ECS
├── day07_data_services/               SNS/SQS・Athena・Lambda
├── day08_workshop_level2/             Level 2 ワークショップ（サーバーレスETL）
├── day09_network_security/            VPC・RDS・IAM・Secrets Manager
└── day10_workshop_level3/             Level 3 ワークショップ（マイクロサービス基盤）
```

各Dayのディレクトリには以下のファイルが含まれます:

- **README.md**: メインの説明資料（座学・解説・要件・チェックリスト）
- **examples/**: 実行可能なソースコード例（Terraform `.tf`, Node.js, Dockerfile 等）
- **supplementary.md / architecture.md / troubleshooting.md**: 補足資料

---

## 全体スケジュール

| 日        | テーマ                                                                 | 形式                   | リンク                                                       |
| --------- | ---------------------------------------------------------------------- | ---------------------- | ----------------------------------------------------------- |
| **Day 0** | **環境準備（AWSアカウント・AWS CLI・Terraform）**                      | **セルフセットアップ** | [day00_setup](./day00_setup/README.md)                          |
| Day 1     | クラウドとAWSの基礎概念                                                | 座学                   | [day01_cloud_basics](./day01_cloud_basics/README.md)            |
| Day 2     | AWSコンソール操作・AWS CLI（プロファイル・SSO）                        | ハンズオン             | [day02_awscli](./day02_awscli/README.md)                        |
| Day 3     | Terraform入門（HCL・state・plan/apply）                                | 座学 + ハンズオン      | [day03_terraform_intro](./day03_terraform_intro/README.md)      |
| Day 4     | Terraform実践（モジュール・変数・backend）                             | ハンズオン             | [day04_terraform_practice](./day04_terraform_practice/README.md) |
| Day 5     | **Level 1 ワークショップ** — S3静的サイト + CloudFront                 | ワークショップ         | [day05_workshop_level1](./day05_workshop_level1/README.md)      |
| Day 6     | コンテナ基礎（Docker・ECR・App Runner / ECS Fargate）                  | 座学 + ハンズオン      | [day06_container](./day06_container/README.md)                  |
| Day 7     | データサービス（SNS/SQS・Athena・Lambda）                             | 座学 + ハンズオン      | [day07_data_services](./day07_data_services/README.md)          |
| Day 8     | **Level 2 ワークショップ** — サーバーレスデータパイプライン            | ワークショップ         | [day08_workshop_level2](./day08_workshop_level2/README.md)      |
| Day 9     | ネットワーク・DB・セキュリティ（VPC・RDS・IAM・Secrets Manager）       | 座学 + ハンズオン      | [day09_network_security](./day09_network_security/README.md)    |
| Day 10    | **Level 3 ワークショップ** — マイクロサービス基盤構築                  | ワークショップ         | [day10_workshop_level3](./day10_workshop_level3/README.md)      |

---

## コスト設計方針

AWSにはGCPのような一律の無料トライアルクレジット（$300）はありません。代わりに **AWS無料利用枠（Free Tier）** があり、これは次の3種類で構成されます。

- **12ヶ月間無料**: アカウント作成から12ヶ月間、一定量まで無料（EC2, RDS, S3 など）
- **常時無料 (Always Free)**: 期限なしで一定量まで無料（Lambda, SQS, DynamoDB など）
- **トライアル**: 特定サービスの短期お試し枠

本研修は、無料利用枠と最小構成のリソースで、合計でも数ドル〜20ドル程度に収まるよう設計します。

| サービス               | 無料枠                              | 本研修での利用量目安 | 目安コスト          |
| ---------------------- | ----------------------------------- | -------------------- | ------------------- |
| S3                     | 5 GB（12ヶ月）                      | 数MB                 | $0                  |
| CloudFront             | 1 TB/月 アウト（常時無料）          | 数MB                 | $0                  |
| Lambda                 | 100万リクエスト/月（常時無料）      | 数十回               | $0                  |
| SQS / SNS              | 各100万リクエスト/月（常時無料）    | 数十件               | $0                  |
| Athena                 | 従量（$5 / スキャン1TB）            | 数MB                 | $0                  |
| ECR                    | 500 MB（12ヶ月）                    | image数個            | $0                  |
| App Runner / ECS Fargate | **無料枠なし**                    | ハンズオン程度       | **$0〜$2**          |
| RDS                    | 750時間 db.t3.micro（12ヶ月）       | db.t3.micro × 数時間 | **$0〜$5**          |
| ALB                    | **無料枠なし**                      | 数時間               | **$1〜3**           |
| NAT Gateway            | **無料枠なし**                      | 数時間               | **$1〜3**           |
| Secrets Manager        | **無料枠なし**（$0.40/シークレット/月） | 数個              | **$0〜$1**          |

**推定合計: $5〜20**

⚠️ 各ワークショップ終了後は必ず `terraform destroy` を実行してください。特に RDS・ALB・NAT Gateway は時間課金のため、放置すると数日で数十ドルかかります。

---

## 学習の進め方

1. **Day 0 で環境構築を完了する**: ここでつまずくと後続のハンズオンができません。
2. **座学 → ハンズオン → ワークショップ の順で進む**: 知識を積み上げていく構成です。
3. **各Dayの「確認課題」を必ず実行する**: 手を動かさないと身につきません。
4. **ワークショップでは `terraform destroy` を忘れない**: 課金が発生するリソースが含まれます。

---

## 参考リンク

- Terraform AWS Provider: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- AWS 無料利用枠: https://aws.amazon.com/free/
- AWS CLI: https://docs.aws.amazon.com/cli/latest/userguide/
- App Runner: https://docs.aws.amazon.com/apprunner/latest/dg/
- Lambda: https://docs.aws.amazon.com/lambda/latest/dg/
- Athena: https://docs.aws.amazon.com/athena/latest/ug/
- RDS: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/
- Terraform ベストプラクティス: https://developer.hashicorp.com/terraform/cloud-docs/recommended-practices
