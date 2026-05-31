# Day 1 補足: IAMの考え方とAWSサービス対応表

## IAMの構成要素

GCPのIAMは「誰が（プリンシパル）」「何をしてよいか（ロール）」「どこに対して（リソース）」の3要素で表現します。

```
ポリシー = プリンシパル + ロール + リソース
```

### プリンシパルの種類

| プリンシパル | 形式例 | 用途 |
| --- | --- | --- |
| ユーザー | `user:alice@example.com` | 人間 |
| グループ | `group:devs@example.com` | 部署・チーム |
| サービスアカウント | `serviceAccount:my-sa@PROJECT.iam.gserviceaccount.com` | アプリケーション/サービス |
| 全ユーザー（インターネット公開） | `allUsers` | 静的サイト公開等 |
| 全Google認証ユーザー | `allAuthenticatedUsers` | 認証だけ要求 |

### ロールの種類

| 種類 | 例 | 説明 |
| --- | --- | --- |
| 基本ロール | `roles/owner`, `roles/editor`, `roles/viewer` | プロジェクト全体に対する権限。**実運用では避ける**（強すぎる） |
| 事前定義ロール | `roles/storage.objectViewer`, `roles/run.invoker` | サービスごとに細かく定義済み。**通常はこちらを使う** |
| カスタムロール | 自分で定義 | 事前定義で足りない場合のみ |

### サービスアカウントの基本

サービスアカウントは「アプリケーション用のユーザー」です。Cloud Run や Cloud Functions などのワークロードは、サービスアカウントの権限で動きます。

**重要な原則**:
- サービスごとに専用のサービスアカウントを作成する
- 必要最小限のロールだけ付与する（最小権限の原則）
- サービスアカウントキー（JSON）は可能な限り使わず、GCP内部の認証（メタデータサーバー）に任せる

---

## AWSサービスとの対応表

GCPとAWSは概念的に近いサービスが多いですが、名前と細部が異なります。AWS経験者向けの対応表です。

| カテゴリ | GCP | AWS | 備考 |
| --- | --- | --- | --- |
| 仮想マシン | Compute Engine (GCE) | EC2 | |
| サーバーレスコンテナ | **Cloud Run** | ECS Fargate / App Runner | Cloud Runの方が簡単 |
| サーバーレス関数 | Cloud Functions | Lambda | |
| Kubernetes | GKE | EKS | |
| オブジェクトストレージ | Cloud Storage (GCS) | S3 | |
| マネージドRDB | Cloud SQL | RDS | |
| データウェアハウス | BigQuery | Redshift / Athena | BigQueryはサーバーレス |
| メッセージング | Pub/Sub | SNS + SQS | Pub/Subは1サービスで両機能 |
| 仮想ネットワーク | VPC | VPC | リージョン跨ぎの扱いが異なる |
| ロードバランサー | HTTP(S) LB | ALB | |
| CDN | Cloud CDN | CloudFront | |
| DNS | Cloud DNS | Route 53 | |
| シークレット管理 | Secret Manager | Secrets Manager | |
| コンテナレジストリ | Artifact Registry | ECR | |
| IAM | Cloud IAM | IAM | リソース階層の考え方が違う |
| API Gateway | API Gateway | API Gateway | GCP版は OpenAPI spec ベース |

---

## リソース階層の違い (GCP vs AWS)

```
GCP:
  組織 → フォルダ → プロジェクト → リソース
  （プロジェクト単位で課金・IAM・APIが管理される）

AWS:
  Organization → OU → Account → Resource (リージョン別)
  （アカウント単位で課金・IAMが管理される）
```

GCPの「プロジェクト」は、AWSの「アカウント」より軽量に作成・削除できる単位です。研修や開発環境ごとにプロジェクトを分けるのが一般的です。
