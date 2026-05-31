# --- ベースイメージ（Node.js 20 の軽量版） ---
FROM node:20-slim

# --- メタデータ（任意だが管理上便利） ---
LABEL maintainer="training-team"

# --- アプリケーション用の環境変数 ---
# ENV はコンテナ実行時に参照できる環境変数を設定する
# Cloud Run 側の env 設定で上書きも可能
ENV APP_NAME="hello-app"
ENV NODE_ENV="production"

# --- 作業ディレクトリの設定 ---
WORKDIR /app

# --- 依存関係のインストール（キャッシュ効率のため先にpackage.jsonだけCOPY） ---
COPY package*.json ./
RUN npm ci --only=production

# --- アプリケーションコードのコピー ---
COPY . .

# --- Cloud Run はPORT環境変数で待受ポートを指定する ---
# EXPOSE はドキュメント目的（Cloud Run は PORT 環境変数を優先する）
EXPOSE 8080

# --- コンテナ起動時のコマンド ---
CMD ["npm", "start"]
