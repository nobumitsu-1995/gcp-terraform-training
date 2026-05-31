# Day 6: コンテナ革命 — Docker と App Runner でどこでも動くアプリを作る

**ゴール**: 「自分のPCでは動いたのに…」問題を解決するコンテナ技術を理解し、サーバーレスでコンテナを実行できるApp Runnerを使いこなす。

---

## Day 5までの課題

Day 5までは、EC2（仮想マシン）やS3（静적ホスティング）の上にアプリケーションをデプロイする方法を学びました。しかし、そこには次のような課題が潜んでいます。

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

## 3. ハンズオン: アプリをコンテナ化し、App Runnerへデプロイする

ここからは、実際に手を動かしてコンテナ化からデプロイまでの一連の流れを体験します。GCPの **Artifact Registry + Cloud Run** に相当するのが、AWSの **ECR + App Runner** です。

サンプルコード: [examples/hello-app/](./examples/hello-app/)

### ステップ1: コンテナイメージをビルドする (Docker)

まず、Dockerfileを元にコンテナイメージを作成します。

> ⚠️ **Apple Silicon (M1/M2/M3) PC をお使いの方へ**
> App Runnerなどのクラウドサービスは、多くが `x86_64` (Intel/AMD) アーキテクチャのCPUで動作します。Apple Siliconは `ARM` アーキテクチャのため、互換性のあるイメージを作成するために `--platform linux/amd64` オプションが必要です。

```bash
cd docs/aws/day06_container/examples/hello-app

# (Apple Silicon の場合)
docker build --platform linux/amd64 -t hello-app:v1 .

# (Intel/AMD PC の場合)
docker build -t hello-app:v1 .
```

### ステップ2: イメージをECRに登録する (Elastic Container Registry)

ビルドしたイメージは、まだあなたのPCの中にしかありません。App Runnerから利用できるように、**ECR (Elastic Container Registry)** というコンテナイメージの保管庫にアップロードします。

```bash
# 1. AWSアカウントIDとリージョンを変数に設定
export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export REGION=ap-northeast-1

# 2. ECRにイメージを保管するリポジトリを作成
aws ecr create-repository --repository-name training-repo --region ${REGION}

# 3. DockerクライアントをECRにログインさせる
# get-login-password で一時的なパスワードを取得し、docker login に渡しています
aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com

# 4. ECRで管理するための正式なイメージ名を付けてタグ付け
# フォーマット: {アカウントID}.dkr.ecr.{リージョン}.amazonaws.com/{リポジトリ名}:{タグ}
export IMAGE_URI="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/training-repo:v1"
docker tag hello-app:v1 ${IMAGE_URI}

# 5. イメージをECRにプッシュ（アップロード）
docker push ${IMAGE_URI}
```

### ステップ3: App Runnerでコンテナをデプロイする

ECRに登録したイメージを使って、App Runnerサービスを起動します。App Runnerは、コンテナをデプロイするだけで、HTTPS化された公開URL、負荷に応じたオートスケール、ロードバランシングなどを自動で提供してくれるフルマネージドサービスです。

### ステップ4: Terraformでここまでの作業を自動化する

ここまでの手作業を、Terraformで自動化しましょう。
[examples/hello-app/terraform/](./examples/hello-app/terraform/) に、ECRリポジトリとApp Runnerサービスを定義したコードがあります。

```hcl
# main.tf

# ECRリポジトリ
resource "aws_ecr_repository" "repo" {
  name = "training-repo"
}

# App Runner サービス
resource "aws_apprunner_service" "hello" {
  service_name = "hello-app"

  source_configuration {
    image_repository {
      image_identifier      = var.image_uri # デプロイするイメージのURI
      image_repository_type = "ECR"
      port                  = 8080
    }
    authentication_configuration {
      # App RunnerがECRからイメージをpullするための権限
      access_role_arn = aws_iam_role.apprunner_ecr_role.arn
    }
  }
}
```

このTerraformコードを実行してみましょう。

```bash
# 環境変数を設定
# ステップ2でECRにプッシュしたイメージのURIを渡します
export TF_VAR_image_uri=${IMAGE_URI}

cd docs/aws/day06_container/examples/hello-app/terraform
terraform init
terraform apply

# デプロイ完了後、払い出されたURLにアクセス
curl "$(terraform output -raw service_url)"
```
ECRリポジトリの作成や、App RunnerがECRにアクセスするためのIAMロールの作成なども、すべてTerraformで自動化されていることが分かります。

---

## 次のステップ

コンテナの基本をマスターしたところで、次はより複雑なデータ処理サービスを構築します。

→ [Day 7: データサービス（SNS/SQS・Athena・Lambda）](../day07_data_services/README.md)