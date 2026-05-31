# Day 6: コンテナ基礎（Docker・Cloud Run）

**ゴール**: Dockerの基礎とCloud Runでコンテナをデプロイする方法を理解する。

---

## 1. 座学トピック

### コンテナとは何か

| 概念 | 説明 |
| --- | --- |
| **イメージ** | コンテナの実行に必要なファイル一式をまとめたもの（読み取り専用のスナップショット） |
| **コンテナ** | イメージから起動したプロセス（書き込み可能） |
| **レジストリ** | イメージを保管・配布する場所（Artifact Registry, ECR, Docker Hub等） |

### VM とコンテナの違い

```
[ VM ]                          [ Container ]
┌─────────┐ ┌─────────┐          ┌─────┐ ┌─────┐ ┌─────┐
│  App A  │ │  App B  │          │ App │ │ App │ │ App │
├─────────┤ ├─────────┤          │  A  │ │  B  │ │  C  │
│ ゲストOS│ │ ゲストOS│          └─────┘ └─────┘ └─────┘
├─────────┤ ├─────────┤          ┌────────────────────┐
│ Hypervisor          │          │  コンテナランタイム│
├─────────────────────┤          ├────────────────────┤
│ ホストOS            │          │ ホストOS           │
└─────────────────────┘          └────────────────────┘
重い、分単位で起動                  軽量、秒単位で起動
```

### Dockerfile の基本

| 命令 | 説明 |
| --- | --- |
| `FROM` | ベースイメージ |
| `WORKDIR` | 作業ディレクトリを設定 |
| `COPY` | ホストからファイルをコピー |
| `RUN` | ビルド時にコマンドを実行 |
| `ENV` | 環境変数を設定 |
| `EXPOSE` | コンテナが listen するポート（ドキュメント目的） |
| `CMD` | コンテナ起動時に実行するコマンド |

### Cloud Run の特徴

- リクエスト駆動: リクエストが来たときだけコンテナを起動
- ゼロスケール: リクエストがない時間はインスタンス数 0（課金されない）
- 自動スケール: 負荷に応じて自動で水平スケール
- リビジョン管理: デプロイごとに新しいリビジョンを作成、トラフィック分散可能

### Cloud Run vs GCE vs GKE

| | Cloud Run | GCE | GKE |
| --- | --- | --- | --- |
| 種類 | サーバーレス | IaaS | マネージドKubernetes |
| 管理単位 | コンテナ | 仮想マシン | Pod |
| 起動 | リクエスト駆動 | 常時稼働 | 常時稼働 |
| 向いている用途 | HTTPサービス、API | カスタムOSや常時稼働ワーカー | 複雑なマイクロサービス |

詳細な使い分けは [supplementary.md](./supplementary.md) を参照。

---

## 2. ハンズオン — Cloud Run に最初のアプリをデプロイ

サンプル: [examples/hello-app/](./examples/hello-app/)

### アプリケーション（Node.js + Express）

[examples/hello-app/app.js](./examples/hello-app/app.js):

```javascript
const express = require("express");
const app = express();

const PORT = process.env.PORT || 8080;
const APP_NAME = process.env.APP_NAME || "hello-app";

app.get("/", (req, res) => {
  res.json({
    message: "Hello from Cloud Run!",
    app: APP_NAME,
    revision: process.env.K_REVISION || "unknown",
  });
});

app.get("/health", (req, res) => res.json({ status: "ok" }));

app.listen(PORT, "0.0.0.0", () => {
  console.log(`${APP_NAME} listening on port ${PORT}`);
});
```

### Dockerfile

[examples/hello-app/Dockerfile](./examples/hello-app/Dockerfile):

```dockerfile
FROM node:20-slim
LABEL maintainer="training-team"

ENV APP_NAME="hello-app"
ENV NODE_ENV="production"

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .

EXPOSE 8080
CMD ["npm", "start"]
```

### デプロイ手順（gcloud CLI）

```bash
# 1. Artifact Registry にリポジトリ作成
gcloud artifacts repositories create training-repo \
  --repository-format=docker \
  --location=asia-northeast1

# 2. Docker 認証設定
gcloud auth configure-docker asia-northeast1-docker.pkg.dev

# 3. ビルド & プッシュ
docker build -t asia-northeast1-docker.pkg.dev/${GOOGLE_CLOUD_PROJECT}/training-repo/hello-app:v1 .
docker push asia-northeast1-docker.pkg.dev/${GOOGLE_CLOUD_PROJECT}/training-repo/hello-app:v1

# 4. Cloud Run にデプロイ
gcloud run deploy hello-app \
  --image=asia-northeast1-docker.pkg.dev/${GOOGLE_CLOUD_PROJECT}/training-repo/hello-app:v1 \
  --region=asia-northeast1 \
  --allow-unauthenticated \
  --port=8080 \
  --max-instances=2 \
  --cpu=1 --memory=256Mi

# 5. テスト
curl $(gcloud run services describe hello-app --region=asia-northeast1 --format="value(status.url)")
```

### Terraform 版

[examples/hello-app/terraform/main.tf](./examples/hello-app/terraform/main.tf) に Terraform で同等のリソースを定義してあります。

```bash
# 環境変数を設定
export TF_VAR_project_id=$GOOGLE_CLOUD_PROJECT
# Cloud Run にデプロイするコンテナイメージ名を指定
export TF_VAR_container_image="asia-northeast1-docker.pkg.dev/${GOOGLE_CLOUD_PROJECT}/training-repo/hello-app:v1"

cd docs/gcp/day06_container/examples/hello-app/terraform
terraform init
terraform apply
```

---

## 確認課題

Cloud Run にデプロイしたアプリに curl でアクセスし、JSONレスポンスが返ることを確認する。

---

## 次のステップ

→ [Day 7: データサービス（Pub/Sub・BigQuery・Cloud Functions）](../day07_data_services/README.md)
