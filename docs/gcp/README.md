# GCP + Terraform ワークショップ研修資料

**対象者**: インフラ・GCP未経験者（macOS環境）
**期間**: 2週間（Day 0 準備 + 10営業日）
**形式**: 座学 → ハンズオン → ワークショップ（構成図をTerraformで実装）

> 📚 AWS版の講座は [../aws/README.md](../aws/README.md) にあります。

---

## ディレクトリ構成

```
docs/gcp/
├── README.md                          ← このファイル（GCP講座の目次・スケジュール・コスト設計）
├── day00_setup/                       環境準備（GCPアカウント・CLI・Terraform）
├── day01_cloud_basics/                クラウドとGCPの基礎概念
├── day02_gcloud/                      GCPコンソール操作・gcloud CLI
├── day03_terraform_intro/             Terraform入門
├── day04_terraform_practice/          Terraform実践パターン
├── day05_workshop_level1/             Level 1 ワークショップ（GCS + LB + CDN）
├── day06_container/                   コンテナ基礎・Cloud Run
├── day07_data_services/               Pub/Sub・BigQuery・Cloud Functions
├── day08_workshop_level2/             Level 2 ワークショップ（サーバーレスETL）
├── day09_network_security/            VPC・Cloud SQL・IAM・Secret Manager
└── day10_workshop_level3/             Level 3 ワークショップ（マイクロサービス基盤）
```

各Dayのディレクトリには以下のファイルが含まれます:

- **README.md**: メインの説明資料（座学・解説・要件・チェックリスト）
- **examples/**: 実行可能なソースコード例（Terraform `.tf`, Node.js, Dockerfile 等）
- **supplementary.md / architecture.md / troubleshooting.md**: 補足資料

---

## 全体スケジュール

| 日        | テーマ                                                                | 形式                   | リンク                                                           |
| --------- | --------------------------------------------------------------------- | ---------------------- | ---------------------------------------------------------------- |
| **Day 0** | **環境準備（GCPアカウント・CLI・Terraform）**                         | **セルフセットアップ** | [day00_setup](./day00_setup/README.md)                           |
| Day 1     | クラウドとGCPの基礎概念                                               | 座学                   | [day01_cloud_basics](./day01_cloud_basics/README.md)             |
| Day 2     | GCPコンソール操作・gcloud CLI                                         | ハンズオン             | [day02_gcloud](./day02_gcloud/README.md)                         |
| Day 3     | Terraform入門（HCL・state・plan/apply）                               | 座学 + ハンズオン      | [day03_terraform_intro](./day03_terraform_intro/README.md)       |
| Day 4     | Terraform実践（モジュール・変数・backend）                            | ハンズオン             | [day04_terraform_practice](./day04_terraform_practice/README.md) |
| Day 5     | **Level 1 ワークショップ** — GCS静的サイト + LB + CDN                 | ワークショップ         | [day05_workshop_level1](./day05_workshop_level1/README.md)       |
| Day 6     | コンテナ基礎（Docker・Artifact Registry・Cloud Run）                  | 座学 + ハンズオン      | [day06_container](./day06_container/README.md)                   |
| Day 7     | データサービス（Pub/Sub・BigQuery・Cloud Functions）                  | 座学 + ハンズオン      | [day07_data_services](./day07_data_services/README.md)           |
| Day 8     | **Level 2 ワークショップ** — サーバーレスデータパイプライン           | ワークショップ         | [day08_workshop_level2](./day08_workshop_level2/README.md)       |
| Day 9     | ネットワーク・DB・セキュリティ（VPC・Cloud SQL・IAM・Secret Manager） | 座学 + ハンズオン      | [day09_network_security](./day09_network_security/README.md)     |
| Day 10    | **Level 3 ワークショップ** — マイクロサービス基盤構築                 | ワークショップ         | [day10_workshop_level3](./day10_workshop_level3/README.md)       |

---

## コスト設計方針

本研修はGCPの無料トライアル（$300クレジット / 90日間）と Always Free 枠の範囲で完結する設計です。

| サービス          | Always Free枠                   | 本研修での利用量目安 | 目安コスト                    |
| ----------------- | ------------------------------- | -------------------- | ----------------------------- |
| Cloud Storage     | 5 GB/月（US リージョン）        | 数MB                 | $0（asia-northeast1でも数円） |
| Cloud Run         | 200万リクエスト/月, 180k vCPU秒 | ハンズオン程度       | $0〜$1                        |
| Cloud Functions   | 200万呼出/月                    | 数十回               | $0                            |
| Pub/Sub           | 10 GB/月                        | 数KB                 | $0                            |
| BigQuery          | 1 TBクエリ/月, 10 GB保存        | 数MB                 | $0                            |
| Artifact Registry | 500 MB                          | Docker image数個     | $0                            |
| Cloud SQL         | **無料枠なし**                  | db-f1-micro × 数時間 | **$5〜15**                    |
| HTTP(S) LB        | **無料枠なし**                  | 数時間               | **$1〜3**                     |
| Cloud NAT         | **無料枠なし**                  | 数時間               | **$1〜2**                     |
| Secret Manager    | 6アクティブバージョン           | 数個                 | $0                            |

**推定合計: $10〜25（$300クレジットで十分）**

⚠️ 各ワークショップ終了後は必ず `terraform destroy` を実行してください。特にCloud SQLとLBは時間課金のため、放置すると数日で数十ドルかかります。

---

## 学習の進め方

1. **Day 0 で環境構築を完了する**: ここでつまずくと後続のハンズオンができません。
2. **座学 → ハンズオン → ワークショップ の順で進む**: 知識を積み上げていく構成です。
3. **各Dayの「確認課題」を必ず実行する**: 手を動かさないと身につきません。
4. **ワークショップでは `terraform destroy` を忘れない**: 課金が発生するリソースが含まれます。

---

## 参考リンク

- Terraform Google Provider: https://registry.terraform.io/providers/hashicorp/google/latest/docs
- GCP Always Free 枠: https://cloud.google.com/free/docs/free-cloud-features
- Cloud Run: https://cloud.google.com/run/docs
- Pub/Sub: https://cloud.google.com/pubsub/docs
- BigQuery: https://cloud.google.com/bigquery/docs
- Cloud SQL: https://cloud.google.com/sql/docs
- API Gateway: https://cloud.google.com/api-gateway/docs
- Terraform ベストプラクティス: https://cloud.google.com/docs/terraform/best-practices-for-terraform
