# Day 6: コンテナ基礎・App Runner

**ゴール**: Dockerイメージをビルドし、ECR に push、App Runner でデプロイできる。

---

## 1. コンテナとは

アプリケーションと依存関係を1つのイメージにまとめる技術。「自分のPCでは動くのに本番で動かない」問題を解消します。

> 💡 GCPの **Artifact Registry + Cloud Run** に相当するのが、AWSの **ECR + App Runner** です。App Runner は「コンテナを渡すだけでHTTPS付き公開URLとオートスケールを提供する」フルマネージドサービスで、Cloud Run に最も近い体験を得られます。（より細かく制御したい場合は ECS Fargate を使います）

---

## 2. Dockerの基本

```bash
# イメージのビルド
docker build -t hello-app .

# ローカルで実行
docker run -p 8080:8080 hello-app

# 動作確認
curl http://localhost:8080
```

> ⚠️ **Apple Silicon (M1/M2/M3) の場合**: App Runner は x86_64 イメージを要求します。ビルド時に `--platform linux/amd64` を付けてください。
> ```bash
> docker build --platform linux/amd64 -t hello-app .
> ```

---

## 3. ECR へ push

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=ap-northeast-1
REPO="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/hello-repo"

# ECR リポジトリを作成
aws ecr create-repository --repository-name hello-repo --region ${REGION}

# DockerをECRにログイン（認証）
aws ecr get-login-password --region ${REGION} \
  | docker login --username AWS --password-stdin "${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

# イメージにタグ付け
docker tag hello-app "${REPO}:v1"

# push
docker push "${REPO}:v1"
```

---

## 4. App Runner でデプロイ

使用するコード: [examples/hello-app/](./examples/hello-app/)

Terraformでのデプロイは [examples/hello-app/terraform/main.tf](./examples/hello-app/terraform/main.tf) を参照。ECRのイメージURIを変数で渡します。

```bash
cd examples/hello-app/terraform

terraform init
terraform apply -var="image=${REPO}:v1"

# 出力された公開URLにアクセス（デプロイ完了まで数分）
curl "$(terraform output -raw service_url)"
```

> コンソールから作る場合: App Runner →「サービスの作成」→ ソースに ECR を選択 →イメージとポート(8080)を指定、でも同じことができます。

---

## 5. App Runner の特徴

- **フルマネージド**: コンテナを渡すだけで HTTPS 付き公開URL・オートスケールを提供
- **従量課金**: プロビジョニングされたコンテナのメモリ + アクティブ時のCPU/リクエスト処理で課金
- **コンテナベース**: 任意の言語・フレームワークを使える
- **デフォルトで公開**: Cloud Run の `allUsers` のような追加設定なしに公開URLが払い出される

---

## 確認課題

1. Dockerイメージをビルドしてローカルで動かせること。
2. ECR にpushできること。
3. App Runner にデプロイして公開URLにアクセスできること。
4. **後片付け**: `terraform destroy`、および ECR リポジトリの削除。

---

## 次のステップ

→ [Day 7: データサービス（SNS/SQS・Athena・Lambda）](../day07_data_services/README.md)
