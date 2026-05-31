# Day 6: コンテナ革命 — Docker と Cloud Run でどこでも動くアプリを作る

**ゴール**: 「自分のPCでは動いたのに…」問題を解決するコンテナ技術を理解し、サーバーレスでコンテナを実行できるCloud Runを使いこなす。

---

## Day 5までの課題

Day 5までは、GCE（仮想マシン）やGCS（静的ホスティング）の上にアプリケーションをデプロイする方法を学びました。しかし、そこには次のような課題が潜んでいます。

- **環境差異の問題**: 自分の開発PC（例: macOS）と本番サーバー（例: Linux）のOSやライブラリのバージョンが違うため、「自分のPCでは動いたのに、サーバーにデプロイしたら動かない」という問題が頻繁に発生します。
- **セットアップの煩雑さ**: 新しいサーバーを立てるたびに、言語のランタイム、ライブラリ、環境変数などを毎回同じように手動でセットアップする必要があり、手間がかかり、設定ミスも起きやすいです。

この「環境」にまつわる根深い問題を解決するのが、**コンテナ技術**です。

---

## 1. コンテナ技術の核心: 環境ごと持ち運ぶ

コンテナとは、一言で言えば **「アプリケーションが動くために必要な環境（OS、ライブラリ、コード、設定）を丸ごと詰め込んだ箱」** です。

この「箱」の正体が **コンテナイメージ** であり、このイメージさえあれば、Dockerがインストールされているどんなマシン上でも、全く同じようにアプリケーションを動かすことができます。

#### VM（仮想マシン）との違い

| 観点 | VM (仮想マシン) | コンテナ |
| :--- | :--- | :--- |
| **隔離単位** | OSごと | プロセス単位 |
| **サイズ** | 大きい (数GB〜) | 小さい (数MB〜) |
| **起動速度** | 遅い (数分) | 速い (数秒) |
| **オーバーヘッド** | 大きい | 小さい |
| **ポータビリティ** | 低い | 高い |

VMが「家（OS）を丸ごと建てる」イメージなら、コンテナは「家の中の家具や荷物（アプリ）だけを段ボールに詰めて運ぶ」イメージです。ホストOSのカーネルを共有するため、非常に軽量かつ高速に動作します。

---

## 2. Dockerfile: コンテナの「設計図」

コンテナイメージは、**Dockerfile** というテキストファイルに書かれた設計図を元に作成されます。サンプルアプリの [Dockerfile](./examples/hello-app/Dockerfile) を見てみましょう。

```dockerfile
# 1. ベースとなるOSイメージを指定
FROM node:20-slim

# 2. 作者のラベル（任意）
LABEL maintainer="training-team"

# 3. 環境変数を設定
ENV APP_NAME="hello-app"
ENV NODE_ENV="production"

# 4. コンテナ内の作業ディレクトリを作成・移動
WORKDIR /app

# 5. 最初に package.json をコピーして、npm install を実行
COPY package*.json ./
RUN npm ci --only=production

# 6. アプリケーションのソースコードをすべてコピー
COPY . .

# 7. コンテナがリッスンするポートを宣言（ドキュメント目的）
EXPOSE 8080

# 8. コンテナ起動時に実行されるデフォルトコマンド
CMD ["npm", "start"]
```

この設計図は、上から順に実行されます。
1.  `FROM`: `node:20-slim` という軽量なNode.js実行環境イメージを土台にします。
2.  `WORKDIR`: コンテナ内に `/app` ディレクトリを作り、以降のコマンドはそこで実行されます。
3.  `COPY` & `RUN`: `package.json` を先にコピーして `npm ci` を実行するのがポイントです。ソースコードを変更しても `package.json` が変わらなければ、この重い処理はキャッシュが使われ、ビルドが高速になります。
4.  `COPY . .`: アプリの全ソースコードを `/app` にコピーします。
5.  `CMD`: このコンテナが起動したときに `npm start` を実行するよう指定します。

---

## 3. ハンズオン: アプリをコンテナ化し、Cloud Runへデプロイする

ここからは、実際に手を動かしてコンテナ化からデプロイまでの一連の流れを体験します。

サンプルコード: [examples/hello-app/](./examples/hello-app/)

### ステップ1: コンテナイメージをビルドする (Docker)

まず、Dockerfileを元にコンテナイメージを作成します。

```bash
cd docs/gcp/day06_container/examples/hello-app

# 'docker build' コマンドでイメージをビルドする
# -t オプションで「名前:タグ」を付ける
docker build -t hello-app:v1 .
```

### ステップ2: イメージをレジストリに登録する (Artifact Registry)

ビルドしたイメージは、まだあなたのPCの中にしかありません。Cloud Runなど他のサービスから利用できるように、**Artifact Registry** というコンテナイメージの保管庫にアップロードします。

```bash
# 1. GCPでイメージを保管するリポジトリを作成
gcloud artifacts repositories create training-repo \
  --repository-format=docker \
  --location=asia-northeast1

# 2. gcloud経由でDockerがArtifact Registryにアクセスできるよう認証設定
gcloud auth configure-docker asia-northeast1-docker.pkg.dev

# 3. Artifact Registryで管理するための正式なイメージ名を付けてビルド
# フォーマット: {リージョン}-docker.pkg.dev/{プロジェクトID}/{リポジトリ名}/{イメージ名}:{タグ}
docker build -t asia-northeast1-docker.pkg.dev/${GOOGLE_CLOUD_PROJECT}/training-repo/hello-app:v1 .

# 4. イメージをArtifact Registryにプッシュ（アップロード）
docker push asia-northeast1-docker.pkg.dev/${GOOGLE_CLOUD_PROJECT}/training-repo/hello-app:v1
```

### ステップ3: Cloud Runでコンテナをデプロイする

いよいよ、Artifact Registryに登録したイメージを使って、Cloud Runサービスを起動します。

```bash
# 'gcloud run deploy' コマンドでデプロイ
gcloud run deploy hello-app \
  --image=asia-northeast1-docker.pkg.dev/${GOOGLE_CLOUD_PROJECT}/training-repo/hello-app:v1 \
  --region=asia-northeast1 \
  --allow-unauthenticated \
  --port=8080
```
- `--image`: デプロイするコンテナイメージを指定します。
- `--allow-unauthenticated`: 誰でもアクセスできるパブリックなサービスとして公開します。
- `--port`: コンテナがリッスンしているポート（Dockerfileの`EXPOSE`と対応）を指定します。

デプロイが完了するとURLが表示されるので、ブラウザや`curl`でアクセスしてみましょう。

### ステップ4: Terraformでここまでの作業を自動化する

ここまでの手作業を、Terraformで自動化しましょう。
[examples/hello-app/terraform/](./examples/hello-app/terraform/) に、Artifact RegistryリポジトリとCloud Runサービスを定義したコードがあります。

```hcl
# main.tf

# Artifact Registry リポジトリ
resource "google_artifact_registry_repository" "repo" {
  location      = var.region
  repository_id = "training-repo"
  format        = "DOCKER"
}

# Cloud Run サービス
resource "google_cloud_run_v2_service" "hello" {
  name     = "hello-app"
  location = var.region

  template {
    containers {
      image = var.container_image # デプロイするイメージ名を指定
      ports {
        container_port = 8080
      }
    }
  }
}
```

このTerraformコードを実行してみましょう。

```bash
# 環境変数を設定
export TF_VAR_project_id=$GOOGLE_CLOUD_PROJECT
export TF_VAR_region="asia-northeast1"
# デプロイするコンテナイメージ名を指定
export TF_VAR_container_image="asia-northeast1-docker.pkg.dev/${GOOGLE_CLOUD_PROJECT}/training-repo/hello-app:v1"

cd docs/gcp/day06_container/examples/hello-app/terraform
terraform init
terraform apply
```
`gcloud run deploy` で行った設定が、`google_cloud_run_v2_service` リソースの引数として宣言的に定義されていることが分かります。

---

## 次のステップ

コンテナの基本をマスターしたところで、次はより複雑なデータ処理サービスを構築します。

→ [Day 7: データサービス（Pub/Sub・BigQuery・Cloud Functions）](../day07_data_services/README.md)

---

<br>

## トラブルシューティング: よくあるエラー

### エラー: `exec format error` でデプロイが失敗する

Apple Silicon (M1, M2, M3など) 搭載のMacで `docker build` を行ったイメージをCloud Runにデプロイすると、コンテナが起動せずに `exec format error` というログが出力され、デプロイに失敗することがあります。

-   **原因**: あなたが使っているMacのCPUアーキテクチャ (`ARM64`) と、Cloud Runの実行環境のCPUアーキテクチャ (`AMD64`) が異なるためです。`ARM64` 用にビルドされたイメージは、`AMD64` 環境では実行できません。

-   **解決策**: `docker build` コマンドに `--platform linux/amd64` オプションを追加し、Cloud Runの環境に合わせたアーキテクチャのイメージを明示的にビルドします。

    ```bash
    # 修正前
    # docker build -t [イメージ名] .

    # 修正後
    docker build --platform linux/amd64 -t [イメージ名] .
    ```

    例えば、ハンズオンのステップ2は以下のようになります。

    ```bash
    # Artifact Registryで管理するための正式なイメージ名を付けてビルド
    docker build --platform linux/amd64 -t asia-northeast1-docker.pkg.dev/${GOOGLE_CLOUD_PROJECT}/training-repo/hello-app:v1 .
    ```
<br>

---
