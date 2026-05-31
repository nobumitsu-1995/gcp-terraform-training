# Day 9: ネットワーク・DB・セキュリティ（VPC・RDS・IAM・Secrets Manager）

**ゴール**: VPCネットワーク、RDS、Secrets Manager を理解し、セキュアな構成を組めるようになる。

---

## 1. VPC（Virtual Private Cloud）

### VPCの構成要素

| 要素 | 役割 |
| --- | --- |
| **VPC** | 仮想ネットワーク全体 |
| **サブネット** | AZに紐づくIPアドレス範囲（public / private） |
| **セキュリティグループ** | インスタンス単位の**ステートフル**なファイアウォール |
| **ネットワークACL** | サブネット単位の**ステートレス**なファイアウォール |
| **インターネットゲートウェイ (IGW)** | VPCとインターネットの接続点 |
| **NAT Gateway** | プライベートサブネットのインスタンスが外部へ通信する出口 |
| **ルートテーブル** | サブネットのトラフィックの行き先を定義 |

> 💡 GCPでは Cloud SQL にプライベート接続するため「プライベートサービスアクセス（VPCピアリング）」が必要でした。AWSの **RDSは自分のVPCのサブネットに直接配置される**ため、ピアリングは不要でシンプルです。

---

## 2. RDS

マネージドなリレーショナルDB（PostgreSQL/MySQL/SQL Server/Aurora等）。

| 機能 | 説明 |
| --- | --- |
| **自動バックアップ** | 日次バックアップ + ポイントインタイムリカバリ |
| **マルチAZ (Multi-AZ)** | 別AZにスタンバイを配置して高可用性を実現 |
| **リードレプリカ** | 読み取り負荷分散用のレプリカ |
| **DBサブネットグループ** | 複数AZのサブネットを束ね、その中にRDSを配置する |
| **publicly_accessible = false** | パブリックIPを持たせず、VPC内からのみアクセス可能にする |

> ⚠️ RDS は db.t3.micro が12ヶ月無料枠の対象ですが、枠を超えると時間課金されます。ハンズオン後は必ず削除してください。

---

## 3. Secrets Manager

APIキーやDBパスワードなどの機密情報を安全に保管するサービス。

- バージョン管理される
- IAMでアクセス制御
- コードに秘密情報をハードコードする必要がなくなる

```bash
# シークレットの作成
aws secretsmanager create-secret --name db-password --secret-string "my-db-password"

# シークレットの取得
aws secretsmanager get-secret-value --secret-id db-password --query SecretString --output text
```

> 💡 Secrets Manager は1シークレットあたり月$0.40の課金があります（無料枠なし）。軽量な用途では SSM Parameter Store（SecureString）が無料の代替になります。

---

## 4. ハンズオン

サンプル: [examples/vpc-rds/](./examples/vpc-rds/)

VPC + RDS（プライベート）+ Secrets Manager の構成をTerraformで構築します。

```bash
cd examples/vpc-rds
terraform init
terraform apply -var="db_password=YOUR_PASSWORD"

# 後片付け（重要：RDSは課金される）
terraform destroy -var="db_password=YOUR_PASSWORD"
```

---

## 確認課題

1. VPCと2つのプライベートサブネットが作成されること
2. RDSインスタンスが `publicly_accessible = false` で作成されること
3. DBパスワードがSecrets Managerに保管されること

---

## 補足

- セキュリティのベストプラクティス: [supplementary.md](./supplementary.md)

---

## 次のステップ

→ [Day 10: Level 3 ワークショップ — マイクロサービス基盤構築](../day10_workshop_level3/README.md)
