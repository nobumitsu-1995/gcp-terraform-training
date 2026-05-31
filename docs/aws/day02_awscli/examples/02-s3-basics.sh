#!/usr/bin/env bash
# Day 2: S3バケットの基本操作

set -euo pipefail

# バケット名はグローバルで一意である必要があるため、アカウントIDを接頭辞にする
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET="s3://${ACCOUNT_ID}-training-test"
REGION="ap-northeast-1"

# バケット作成
aws s3 mb "${BUCKET}" --region "${REGION}"

# ファイルをアップロード
echo "<h1>Hello AWS</h1>" > index.html
aws s3 cp index.html "${BUCKET}/"

# 一覧表示
aws s3 ls "${BUCKET}/"

# 後片付け（中身ごと削除）
aws s3 rb "${BUCKET}" --force
