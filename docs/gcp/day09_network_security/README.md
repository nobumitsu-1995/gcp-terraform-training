# Day 9: 鉄壁の守り — VPC, ファイアウォール, Cloud SQL, Secret Manager

**ゴール**: クラウドセキュリティの基本原則を理解し、VPC, ファイアウォール、プライベートDB、Secret Managerを組み合わせたセキュアなインフラを構築できるようになる。

---

## これまでの課題

Day 8までのワークショップでは、アプリケーションの機能開発に焦点を当ててきました。しかし、私たちが構築したサービスは、基本的に誰でもアクセスできるパブリックなインターネット上にありました。

もし、アプリケーションが顧客の個人情報や決済情報のような極めて重要なデータを扱うとしたら、どうやって悪意のある攻撃から守るのでしょうか？

クラウドにおけるセキュリティの基本は **「最小権限の原則」** です。これは、許可された人やサービスだけが、許可された方法で、必要な情報にのみアクセスできるようにするという考え方です。これを実現するために、私たちはインフラに「城壁」と「門番」、そして「金庫」を構築する必要があります。

---

## 1. 城壁: 自分だけのプライベート空間 VPC

最初のステップは、外部のインターネットから隔離された、自分たちだけのプライベートなネットワーク空間を作ることです。これが **VPC (Virtual Private Cloud)** の役割です。

VPCは、GCPの中に構築する「城壁」に囲まれた土地のようなものです。このVPC内にサーバーやデータベースを配置することで、インターネットからの直接的な攻撃を防ぎます。

-   **サブネット**: VPCという広大な土地を、さらに「Webサーバー地区」「アプリケーションサーバー地区」「データベース地区」のように役割ごとに区切ったものがサブネットです。
-   **IPアドレス範囲 (CIDR)**: VPCやサブネットに割り当てる、プライベートなIPアドレスの範囲です（例: `10.0.0.0/8`）。このアドレスはVPC内でしか通用しないため、外部から直接アクセスすることはできません。

---

## 2. 門番: 通信を制御するファイアウォール

城壁（VPC）を築いただけでは、誰も中に入れません。そこで、特定の通信だけを選択的に許可する「門番」が必要になります。これが **ファイアウォールルール** です。

GCPのファイアウォールの基本原則は **「デフォルトで入口はすべて閉鎖、出口はすべて開放」** です。つまり、何もしなければ、VPCの中から外への通信はできますが、外から中への通信は一切できません。

このため、「ポート443（HTTPS）への通信は許可する」といったルールを明示的に追加していくことで、必要な通信だけを安全に受け入れることができます。

---

## 3. 城内の宝物庫: Cloud SQLとプライベート接続

データベースは、アプリケーションの「宝物庫」です。これをパブリックIPアドレスでインターネットに晒すのは、宝物庫を城壁の外に野ざらしにするようなもので、絶対にあってはなりません。

そこで、**Cloud SQL** のようなデータベースサービスは、**プライベートIP接続** を使ってVPC内に配置します。

これにより、Cloud SQLはパブリックIPアドレスを持たず、VPC内のアプリケーションからのみアクセスできるようになります。データベースへのアクセス経路をVPC内に限定することで、セキュリティは劇的に向上します。

---

## 4. 宝物庫の鍵: 機密情報を守るSecret Manager

データベースのパスワードや、外部サービスのAPIキーといった機密情報（シークレット）をどう管理するかも重要な問題です。

ソースコードや設定ファイルに直接書き込むのは最悪の手段です。もしコードがGitHubなどで漏洩したら、パスワードも一緒に漏洩し、宝物庫の鍵を世界中に公開するのと同じことになってしまいます。

そこで登場するのが **Secret Manager** です。Secret Managerは、これらの機密情報を暗号化して安全に保管し、厳格なアクセス制御（IAM）の元でアプリケーションに必要な時だけ渡してくれる、まさに「宝物庫の鍵を管理する金庫」です。

---

## 5. ハンズオン: TerraformでセキュアなDBネットワークを構築する

ここまでの概念を組み合わせ、Terraformを使って「VPC内にプライベートIPのみを持つCloud SQLを構築し、そのパスワードをSecret Managerで管理する」というセキュアな構成を自動で構築します。

サンプルコード: [examples/vpc-sql/](./examples/vpc-sql/)

### `network.tf` のポイント: VPCとプライベート接続の準備

VPC本体 (`google_compute_network`) とサブネット (`google_compute_subnetwork`) を作成します。Cloud SQLをプライベート接続するために、`google_service_networking_connection` というリソースで、私たちのVPCとGoogleのサービスネットワークを内部的に接続する設定が不可欠です。

```hcl
# network.tf

# VPCとGoogleサービスをプライベート接続するための予約済みIP範囲
resource "google_compute_global_address" "private_ip" {
  name          = "private-ip-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.main.id
}

# VPCとGoogleサービスネットワークのピアリング接続
resource "google_service_networking_connection" "private_vpc" {
  network                 = google_compute_network.main.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip.name]
}
```

### `rds.tf` のポイント: プライベートIPのみを持つCloud SQL

`google_sql_database_instance` リソースで、`settings.ip_configuration` ブロックの設定がセキュリティの鍵です。

```hcl
# rds.tf

resource "google_sql_database_instance" "main" {
  # ...
  settings {
    ip_configuration {
      ipv4_enabled    = false # パブリックIPを無効化！
      private_network = google_compute_network.main.id # 接続先のVPCを指定
    }
  }
  # private_vpc接続が完了してからDBを作成するよう依存関係を明示
  depends_on = [google_service_networking_connection.private_vpc]
}
```

### `secrets.tf` のポイント: パスワードの生成と保管

`random` プロバイダで強力なパスワードを自動生成し、それを `google_secret_manager_secret_version` でSecret Managerに格納します。

```hcl
# secrets.tf

# 24文字のランダムなパスワードを生成
resource "random_password" "db_password" {
  length  = 24
  special = true
}

# Secret Managerにシークレット（入れ物）を作成
resource "google_secret_manager_secret" "db_password" {
  secret_id = "db-password"
  # ...
}

# 生成したパスワードをシークレットの新しいバージョンとして追加
resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db_password.result
}
```

> ⚠️ **Cloud SQL は高価なリソースです。** 演習・確認が終わったら、コストがかかり続けないよう、**必ず `terraform destroy` を実行してリソースを削除してください。**

---

## 次のステップ

クラウドにおけるネットワークとセキュリティの基本要素を学びました。いよいよ最終日、これら全ての知識を総動員して、マイクロサービスアーキテクチャの構築に挑戦します。

→ [Day 10: Level 3 ワークショップ — マイクロサービス基盤](../day10_workshop_level3/README.md)