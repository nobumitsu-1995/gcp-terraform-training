# Day 1 補足: IAMの考え方とGCPサービス対応表

## IAMの構成要素

AWSのIAMは「誰が（プリンシパル）」「何をしてよいか（アクション）」「どのリソースに対して（リソース）」を、**ポリシー（JSONドキュメント）**で表現します。

```
ポリシー = Effect(許可/拒否) + Action(操作) + Resource(対象) + (Condition)
```

GCPがロールを「プリンシパル＋ロール＋リソース」のバインディングで表すのに対し、AWSは**ポリシードキュメントをユーザー/ロールにアタッチする**点が特徴です。

### プリンシパルの種類

| プリンシパル | 説明 | 用途 |
| --- | --- | --- |
| IAMユーザー | 人間や特定システム用の永続的なID | 個人ログイン、CI用など |
| IAMグループ | ユーザーをまとめる箱（権限を一括付与） | 部署・チーム |
| IAMロール | 一時的に引き受ける権限のセット | アプリ・AWSサービス・他アカウント連携 |
| AWSサービス | サービス自身がプリンシパルになる | Lambda が S3 にアクセス 等 |
| ルートユーザー | アカウント最上位の全権限ID | **日常では使わない**（初期設定・請求のみ） |

### ポリシーの種類

| 種類 | 例 | 説明 |
| --- | --- | --- |
| AWS管理ポリシー | `AdministratorAccess`, `AmazonS3ReadOnlyAccess` | AWSが用意した定義済みポリシー。手軽だが広めなことが多い |
| カスタマー管理ポリシー | 自分で作るJSONポリシー | 最小権限に絞りたいとき。**実務の主役** |
| インラインポリシー | ユーザー/ロールに直接埋め込む | 1対1の特殊な権限。再利用しないもの |

> ⚠️ 基本ロール相当の `AdministratorAccess` は強すぎるため、研修以外の実運用では避け、必要なアクションだけを許可するカスタマー管理ポリシーを使います（最小権限の原則）。

### IAMロールの基本

IAMロールは「**一時的に引き受ける権限のセット**」です。Lambda や ECS タスク、EC2 などのワークロードは、アタッチされたロールの権限で動きます（GCPの「サービスアカウント」に相当）。

**重要な原則**:
- ワークロードごとに専用のロールを作成する
- 必要最小限の権限だけ付与する（最小権限の原則）
- 長期的なアクセスキーは可能な限り使わず、ロールによる一時認証情報（STS）に任せる

---

## GCPサービスとの対応表

AWSとGCPは概念的に近いサービスが多いですが、名前と細部が異なります。GCP経験者向けの対応表です。

| カテゴリ | AWS | GCP | 備考 |
| --- | --- | --- | --- |
| 仮想マシン | EC2 | Compute Engine (GCE) | |
| サーバーレスコンテナ | **App Runner / ECS Fargate** | Cloud Run | Cloud Runの方が簡単。App Runnerが最も近い |
| サーバーレス関数 | Lambda | Cloud Functions | |
| Kubernetes | EKS | GKE | |
| オブジェクトストレージ | S3 | Cloud Storage (GCS) | |
| マネージドRDB | RDS | Cloud SQL | |
| データ分析・DWH | Athena / Redshift | BigQuery | BigQueryはサーバーレス。Athenaが概念的に近い |
| メッセージング | **SNS + SQS** | Pub/Sub | AWSは発行/購読(SNS)とキュー(SQS)が別 |
| 仮想ネットワーク | VPC | VPC | AWSはサブネットがAZ単位 |
| ロードバランサー | ALB | HTTP(S) LB | |
| CDN | CloudFront | Cloud CDN | |
| DNS | Route 53 | Cloud DNS | |
| シークレット管理 | Secrets Manager | Secret Manager | |
| コンテナレジストリ | ECR | Artifact Registry | |
| 認可 (IAM) | IAM | Cloud IAM | AWSはポリシーをアタッチ、GCPはロールをバインド |
| API Gateway | API Gateway | API Gateway | |

---

## リソース階層の違い (AWS vs GCP)

```
AWS:
  Organization → OU → Account → Resource (リージョン別)
  （アカウント単位で課金・IAMが管理される）

GCP:
  組織 → フォルダ → プロジェクト → リソース
  （プロジェクト単位で課金・IAM・APIが管理される）
```

AWSの「アカウント」は、GCPの「プロジェクト」より重い単位です。AWSでは環境・用途ごとにアカウント自体を分け、AWS Organizations で束ねて一括請求・一括管理するのが一般的です。一方GCPでは、1つのアカウントの下にプロジェクトを軽量に量産して分離します。

また、AWSのリソースは多くが**リージョン単位**で作成・表示される点にも注意が必要です（IAM・Route 53・CloudFront などはグローバル）。
