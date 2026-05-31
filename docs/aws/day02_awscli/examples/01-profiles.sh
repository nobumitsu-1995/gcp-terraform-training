#!/usr/bin/env bash
# Day 2: AWS CLI 名前付きプロファイルによる複数アカウント管理
# 実行前に: aws --version （v2 を推奨）

set -euo pipefail

# ============================================
# 1. 現在のプロファイル一覧を確認
# ============================================
aws configure list-profiles

# ============================================
# 2. 研修用プロファイルを作成（対話式）
#    Access Key ID / Secret / region(ap-northeast-1) / output(json) を入力
# ============================================
aws configure --profile training

# ============================================
# 3. 認証情報が正しいか確認
# ============================================
aws sts get-caller-identity --profile training

# ============================================
# 4. プロファイルの切り替え
# ============================================
# コマンド単位
aws s3 ls --profile training

# シェル単位（以降のコマンドすべてに適用）
export AWS_PROFILE=training

# ============================================
# 5. (任意) IAM Identity Center (SSO) を使う場合
# ============================================
# aws configure sso --profile training-sso
# aws sso login --profile training-sso
