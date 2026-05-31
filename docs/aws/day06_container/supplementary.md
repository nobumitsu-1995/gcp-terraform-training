# Day 6 補足: Docker / App Runner チートシート

## Dockerコマンド

```bash
docker build -t NAME .          # ビルド
docker build --platform linux/amd64 -t NAME .   # Apple Silicon→x86_64 でビルド
docker images                  # イメージ一覧
docker run -p 8080:8080 NAME   # 実行
docker ps                      # 起動中コンテナ
docker logs CONTAINER          # ログ確認
docker exec -it CONTAINER sh   # シェル接続
```

## Dockerfile のベストプラクティス

```dockerfile
# マルチステージビルドで軽量化
FROM node:20-slim AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .

FROM node:20-slim
WORKDIR /app
COPY --from=builder /app .
CMD ["node", "app.js"]
```

## App Runner の設定項目

| 項目 | 説明 |
| --- | --- |
| CPU | 0.25〜4 vCPU（`cpu = "1024"` は 1 vCPU） |
| メモリ | 0.5〜12 GB（`memory = "2048"` は 2 GB） |
| ポート | コンテナがリッスンするポート（例: 8080） |
| 自動デプロイ | ECRイメージ更新時に自動再デプロイするか |
| オートスケール | 同時実行数に応じてインスタンスを増減（最小1〜） |

## 環境変数とシークレット（Terraform）

```hcl
image_configuration {
  port = "8080"

  runtime_environment_variables = {
    LOG_LEVEL = "info"
  }

  # Secrets Manager / SSM Parameter Store のARNを参照
  runtime_environment_secrets = {
    DB_PASSWORD = aws_secretsmanager_secret.db.arn
  }
}
```

## ECR ライフサイクルポリシー

古いイメージを自動削除してストレージ料金を抑えられます。

```bash
aws ecr put-lifecycle-policy --repository-name hello-repo \
  --lifecycle-policy-text '{"rules":[{"rulePriority":1,"selection":{"tagStatus":"any","countType":"imageCountMoreThan","countNumber":5},"action":{"type":"expire"}}]}'
```

## ECS Fargate という選択肢

より細かいネットワーク制御・サイドカー・長時間バッチが必要なら ECS Fargate を使います。App Runner は「とにかく簡単に1コンテナを公開したい」用途に最適です。

（以下略）
