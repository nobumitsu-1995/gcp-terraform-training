# Day 9: ネットワーク・DB・セキュリティ

**ゴール**: VPC、Cloud SQL、IAM、Secret Manager を理解し Level 3 の準備をする。

---

## 1. 座学トピック

### VPC（Virtual Private Cloud）

- **カスタムモードネットワーク**: サブネット・CIDRを自分で設計する（実務で推奨）
- **オートモード**: GCPが各リージョンに自動でサブネットを作る（簡易だが本番非推奨）
- **CIDR設計**: `10.0.0.0/8` などプライベートアドレス空間から、サブネット同士が重ならないよう切り出す
- **サーバーレスVPCコネクタ**: Cloud Run / Cloud Functions などサーバーレスサービスから VPC リソース（Cloud SQL等）にアクセスするための橋渡し

AWS で例えると **VPC + NAT Gateway** の組み合わせに相当。

### Cloud SQL

- マネージドな RDB（PostgreSQL / MySQL / SQL Server）
- **プライベートIP接続**: パブリックIPを無効化し、VPCピアリングでプライベートIPだけ公開（推奨）
- インスタンスタイプ `db-f1-micro` は研修・開発用の最小構成

AWS で例えると **RDS** に相当。

### ファイアウォールルール

- **ingress（内向き）**: VPCに入ってくる通信を制御（デフォルトは拒否）
- **egress（外向き）**: VPCから出ていく通信を制御（デフォルトは許可）

AWS の Security Group とは挙動が違う（GCPはVPC単位、SGはNIC単位）。

### Cloud NAT / Cloud Router

プライベートサブネットの VM から外部インターネットに出る通信を中継する。例: パブリックIPを持たない Cloud Run / GCE が外部APIを叩く場合に必要。

### Secret Manager

DBパスワードやAPIキーなどの機密情報をバージョン管理付きで保管。Cloud Run の環境変数として参照する場合は、tfstate に平文を残さない運用ができる。

AWS で例えると **Secrets Manager** に相当。

### GCP API Gateway

- OpenAPI 2.0 (Swagger) spec ベースのフルマネージドAPIゲートウェイ
- 3層構造（API → API Config → Gateway）
- Terraform では `google-beta` プロバイダが必要

Day 10 のワークショップで実装します。

---

## 2. ハンズオン — VPC + Cloud SQL

サンプル: [examples/vpc-sql/](./examples/vpc-sql/)

VPC、Cloud SQL（プライベートIP）、Secret Manager をまとめて構築します。

```bash
# 環境変数を設定
export TF_VAR_project_id=$GOOGLE_CLOUD_PROJECT

cd docs/gcp/day09_network_security/examples/vpc-sql
terraform init
terraform apply

# Cloud SQL の作成には10〜15分かかります（焦らず待つ）

# 検証が終わったら必ず destroy
terraform destroy
```

> ⚠️ **Cloud SQL は時間課金です。** `db-f1-micro` でも $0.015/時間（≈ $11/月）かかります。**確認が終わったら必ず `terraform destroy` を実行してください。**

---

## 3. ハンズオンのポイント

### プライベートサービス接続

Cloud SQL を「プライベートIPだけで公開」する場合、VPCピアリングで GoogleManaged のサービスネットワークと自分のVPCを接続する必要があります。

```hcl
resource "google_compute_global_address" "private_ip" {
  name          = "private-ip-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.main.id
}

resource "google_service_networking_connection" "private_vpc" {
  network                 = google_compute_network.main.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip.name]
}
```

`google_sql_database_instance` の作成時には `depends_on = [google_service_networking_connection.private_vpc]` が必須。

### random_password と Secret Manager

```hcl
resource "random_password" "db_password" {
  length  = 24
  special = true
}

resource "google_secret_manager_secret" "db_password" {
  secret_id = "db-password"
  replication { auto {} }
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db_password.result
}
```

> 💡 ただし `random_password.db_password.result` は tfstate に平文で残ります。完全に隔離したい場合は手動でパスワードを Secret Manager に保存し、Cloud SQL ユーザー作成も外で行う運用にする。

---

## 確認課題

1. `terraform apply` 後、Cloud SQL の管理画面で「プライベートIP」だけが設定されていることを確認する
2. Secret Manager のコンソールで `db-password` シークレットが作成されていることを確認する
3. `terraform destroy` でリソースを片付ける

---

## 補足

- VPC / Cloud SQL の落とし穴: [supplementary.md](./supplementary.md)

---

## 次のステップ

→ [Day 10: Level 3 ワークショップ — マイクロサービス基盤](../day10_workshop_level3/README.md)
