#!/usr/bin/env bash
# Day 2 サンプル: GCSバケットの基本操作
#
# gcloud config set project の後に実行してください。

set -euo pipefail

PROJECT_ID="${GOOGLE_CLOUD_PROJECT:-$(gcloud config get-value project)}"
BUCKET="gs://${PROJECT_ID}-test"

echo "▶ バケット作成: ${BUCKET}"
gsutil mb -l asia-northeast1 "${BUCKET}/"

echo "▶ index.html をアップロード"
echo "<h1>Hello GCP</h1>" > /tmp/index.html
gsutil cp /tmp/index.html "${BUCKET}/"

echo "▶ バケット内のファイル一覧"
gsutil ls "${BUCKET}/"

echo "▶ ダウンロードして内容確認"
gsutil cat "${BUCKET}/index.html"

echo "▶ 後片付け（バケットごと削除）"
gsutil rm -r "${BUCKET}/"

echo "✅ GCSの一連の操作が完了しました。"
