# Day 9 補足: VPC / Cloud SQL の落とし穴

## 1. プライベートサービス接続の作成は時間がかかる

`google_service_networking_connection` の作成には数分かかります。`google_sql_database_instance` の作成も合わせると、初回 apply には10〜20分かかることがあります。

```hcl
resource "google_sql_database_instance" "main" {
  # ...
  timeouts {
    create = "30m"  # デフォルト20分から延長
  }
}
```

## 2. destroy 時に「ピアリングが残る」問題

`google_service_networking_connection` は destroy 時に正常に削除されない既知の問題があります。再度同じVPCを作る時、ピアリングが残っているせいで `google_compute_global_address` の作成が失敗することがあります。

回避策:

```bash
# 手動でピアリングを削除
gcloud compute networks peerings delete servicenetworking-googleapis-com \
  --network=training-vpc
```

## 3. Cloud SQL のリストア・バックアップ

研修では使いませんが、実運用では必須です。

```hcl
settings {
  backup_configuration {
    enabled                        = true
    start_time                     = "03:00"  # 日本時間の昼 12:00
    point_in_time_recovery_enabled = true     # PostgreSQL のみ対応
    transaction_log_retention_days = 7
  }
}
```

## 4. tfstate にパスワードが残る問題

`random_password.db_password.result` を Terraform で扱うと、その値は tfstate に平文で残ります。これは Remote Backend（GCS）の暗号化で守られていますが、tfstate ファイルにアクセスできる人には全員パスワードが見えてしまいます。

厳密に守りたい場合の選択肢:

1. **手動でSecretを作成**: Terraform で `google_secret_manager_secret` だけ作り、値はコンソールやスクリプトで投入。Cloud SQL の `google_sql_user.password` は `data "google_secret_manager_secret_version"` で読む
2. **External Secrets Operator** などの仕組みで K8s/Cloud Run へ動的に注入
3. **IAM 認証**: PostgreSQL の IAM Database Authentication を使えばパスワード不要

研修ではコードの読みやすさを優先して `random_password` を使っていますが、本番では選択肢2 か3 を検討してください。

## 5. ファイアウォールルール

VPC内のVM同士の通信は明示的に許可しないと通りません。

```hcl
# プライベートサブネット内の SSH を許可（IAP経由）
resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "allow-iap-ssh"
  network = google_compute_network.main.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # IAP のIP範囲（固定値）
  source_ranges = ["35.235.240.0/20"]
}
```

## 6. サーバーレスVPCコネクタの料金

Cloud Run / Cloud Functions が VPC リソースにアクセスするのに必要ですが、`min_instances = 2` で常時2インスタンス起動しているため **時間課金が発生** します。

| インスタンスサイズ | 課金（asia-northeast1） |
| --- | --- |
| e2-micro | $0.007 / 時間 |
| e2-standard-4 | $0.105 / 時間 |

研修用なら e2-micro 2台で十分（時給 $0.014）。検証が終わったら destroy するのを忘れずに。

## 7. PostgreSQL クライアントツールの導入

接続確認には `psql` が便利。

```bash
brew install postgresql@15
```

Cloud SQL Auth Proxy を使うと VPC 越しに安全に接続できる:

```bash
# Cloud SQL Auth Proxy のインストール
curl -o cloud-sql-proxy https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.7.0/cloud-sql-proxy.darwin.arm64
chmod +x cloud-sql-proxy

# プロキシ起動（別ターミナルで）
./cloud-sql-proxy PROJECT:REGION:INSTANCE_NAME

# 接続
psql "host=127.0.0.1 port=5432 user=appuser dbname=appdb"
```
