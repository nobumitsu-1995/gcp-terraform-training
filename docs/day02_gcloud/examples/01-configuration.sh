#!/usr/bin/env bash
# Day 2 サンプル: gcloud configuration の作成と切り替え
#
# 使い方:
#   bash 01-configuration.sh
# または各コマンドを上から手で実行する。

set -euo pipefail

# ---------------------------------------------
# 1. 現在の configuration 一覧
# ---------------------------------------------
gcloud config configurations list

# ---------------------------------------------
# 2. 研修用の configuration を新規作成
# ---------------------------------------------
gcloud config configurations create training || true   # すでにあってもエラーにしない
gcloud config configurations activate training

# ---------------------------------------------
# 3. アカウント認証
#    （ブラウザが開くので Google アカウントで承認）
# ---------------------------------------------
gcloud auth login
gcloud auth application-default login

# ---------------------------------------------
# 4. プロジェクト・リージョン・ゾーンを設定
# ---------------------------------------------
read -rp "研修用プロジェクトID: " TRAINING_PROJECT
gcloud config set project "${TRAINING_PROJECT}"
gcloud config set compute/region asia-northeast1
gcloud config set compute/zone   asia-northeast1-a

# ---------------------------------------------
# 5. 確認
# ---------------------------------------------
gcloud config configurations list
gcloud config list

cat <<'EOF'

✅ training configuration の作成が完了しました。

切替コマンド:
  gcloud config configurations activate default    # 個人用に戻す
  gcloud config configurations activate training   # 研修用に切替

EOF
