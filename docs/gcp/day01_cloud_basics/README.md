# Day 1: クラウドとGCPの基礎概念

**ゴール**: クラウドの基本モデルとGCPの全体像を掴む。

---

## 学習トピック

### 1. オンプレミスとクラウドの違い

物理サーバーを社内で運用する「オンプレミス」と、Googleなどが運用する設備を借りる「クラウド」では、責任範囲とコスト構造が大きく異なります。クラウドはさらに以下のサービスモデルに分類されます。

| モデル | 例 | ユーザーの責任範囲 |
| --- | --- | --- |
| **IaaS** (Infrastructure as a Service) | GCE, EC2 | OS・ミドルウェア・アプリ全部 |
| **PaaS** (Platform as a Service) | App Engine, Cloud Run | アプリのみ |
| **SaaS** (Software as a Service) | Gmail, Workspace | 利用のみ |
| **CaaS** (Container as a Service) | GKE, Cloud Run | コンテナイメージ |

### 2. GCPの基本コンセプト

- **プロジェクト**: GCPリソースを束ねる単位。課金・IAM・APIの設定がプロジェクト単位で行われる。
- **リージョン / ゾーン**: 地理的なロケーション。リージョン = `asia-northeast1`（東京）、ゾーン = `asia-northeast1-a` のようにリージョン内の物理データセンター。
- **課金アカウント**: 支払い情報を持つアカウント。複数のプロジェクトに紐付け可能。

### 3. リソース階層

```
組織 (Organization)
  └ フォルダ (Folder)        ← 部門・チーム単位での権限管理に使う
      └ プロジェクト (Project)  ← リソースとIAMの境界
          └ リソース (Resource)   ← GCE, GCS, Cloud Run 等
```

個人のGoogleアカウントには「組織」がない場合があります。その場合は「プロジェクト」が最上位の単位となります。

### 4. 主要サービスの俯瞰

本研修で使うサービスを中心に整理します。

| カテゴリ | サービス | 役割 |
| --- | --- | --- |
| Compute | **Cloud Run** | コンテナをサーバーレス実行 |
| Compute | GCE | 仮想マシン（IaaS） |
| Compute | **Cloud Functions** | イベント駆動の小さな関数 |
| Storage | **Cloud Storage (GCS)** | オブジェクトストレージ |
| Storage | **Cloud SQL** | マネージドRDB |
| Storage | **BigQuery** | データウェアハウス |
| Networking | **VPC** | 仮想ネットワーク |
| Networking | **HTTP(S) LB** | ロードバランサー |
| Networking | **Cloud CDN** | CDN |
| Networking | Cloud DNS | DNS |
| Networking | Cloud NAT | プライベートサブネット→外部通信 |
| Messaging | **Pub/Sub** | メッセージング |
| Security | **IAM** | 認可 |
| Security | **Secret Manager** | 秘密情報管理 |
| Security | **Artifact Registry** | コンテナイメージ管理 |

### 5. IAMの基本

詳細は [supplementary.md](./supplementary.md) を参照。

- **プリンシパル**: 誰が（ユーザー、グループ、サービスアカウント）
- **ロール**: 何を許可するか（権限のセット）
- **ポリシー**: どのリソースに対する権限か（プリンシパル + ロール + 対象）
- **サービスアカウント**: ユーザーではなくアプリケーション/サービスのためのID
- **最小権限の原則**: 必要最低限のロールだけを付与する

---

## 確認課題

1. GCPコンソールで研修用の新規プロジェクトを作成する。
2. 「お支払い」→「概要」で課金アカウントが紐付いていることを確認する。
3. 「IAM と管理」→「IAM」で、自分のアカウントが `Owner` ロールを持っていることを確認する。

---

## 次のステップ

→ [Day 2: GCPコンソール操作・gcloud CLI](../day02_gcloud/README.md)
