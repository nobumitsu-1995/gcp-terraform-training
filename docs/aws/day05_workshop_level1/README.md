# Day 5: Level 1 ワークショップ — 静的サイトホスティング

**ゴール**: S3 + CloudFront で静的サイトを公開する。Terraformで一気通貫で構築する。

---

## アーキテクチャ

```
[ユーザー]
   ↓ HTTPS
[CloudFront]（CDN・エッジキャッシュ・HTTPS終端）
   ↓ Origin Access Control (OAC)
[S3 バケット（静的ファイル・非公開）]
```

詳細は [architecture.md](./architecture.md) を参照。

> 💡 GCPでは「Cloud Storage + Load Balancer + Cloud CDN」の3点セットで構成しましたが、AWSでは **CloudFront 単体がCDN・エッジ配信・HTTPS終端をまとめて担う**ため、静的サイトにロードバランサーは不要です。

---

## 構築するリソース

| リソース | 役割 |
| --- | --- |
| `aws_s3_bucket` | 静的ファイルの配置先（非公開） |
| `aws_s3_bucket_public_access_block` | バケットへの直接公開アクセスを遮断 |
| `aws_s3_object` | index.html / 404.html のアップロード |
| `aws_cloudfront_origin_access_control` | CloudFrontがS3を読むための認可 (OAC) |
| `aws_cloudfront_distribution` | CDN配信・HTTPS・エラーページ設定 |
| `aws_s3_bucket_policy` | このCloudFrontからのみ読み取りを許可 |

> 🔒 S3バケットは**非公開のまま**で、CloudFront経由でのみ配信します（OACパターン）。バケットを直接インターネット公開しないのが現在のベストプラクティスです。

---

## 手順

```bash
cd examples/terraform

terraform init
terraform apply

# 出力された CloudFront のURLにアクセス（配信開始まで数分〜十数分かかる）
terraform output site_url
curl "$(terraform output -raw site_url)"
```

---

## 確認課題

1. Terraformで静的サイトをデプロイし、ブラウザで CloudFront URL にアクセスできること。
2. `index.html` を変更して再 `apply` し、CloudFrontのキャッシュ動作（反映の遅延 / 無効化）を確認する。
3. （任意）独自ドメインとACM証明書 (us-east-1) を設定してHTTPSを有効にしてみる。
4. **後片付け**: `terraform destroy` を実行する。

---

## 次のステップ

→ [Day 6: コンテナ基礎・App Runner](../day06_container/README.md)
