#!/usr/bin/env bash
# Day 2 サンプル: 研修で使うAPIを一括有効化する
#
# 事前に gcloud config set project YOUR_PROJECT_ID を実行しておくこと。

set -euo pipefail

gcloud services enable \
  compute.googleapis.com \
  storage.googleapis.com \
  cloudfunctions.googleapis.com \
  run.googleapis.com \
  cloudbuild.googleapis.com \
  artifactregistry.googleapis.com \
  bigquery.googleapis.com \
  pubsub.googleapis.com \
  sqladmin.googleapis.com \
  secretmanager.googleapis.com \
  vpcaccess.googleapis.com \
  dns.googleapis.com \
  servicenetworking.googleapis.com \
  apigateway.googleapis.com \
  servicecontrol.googleapis.com \
  servicemanagement.googleapis.com

echo "✅ 必要なAPIをすべて有効化しました。"
gcloud services list --enabled --filter="config.name~(run|storage|bigquery|pubsub|apigateway)"
