# ============================================================
# 1. GCSバケット（静的サイト）
# ============================================================
resource "google_storage_bucket" "website" {
  name     = "${var.project_id}-static-site" # バケット名（グローバルで一意）
  location = var.region                      # バケットのリージョン

  website {
    main_page_suffix = "index.html" # ルートアクセス時に返すファイル
    not_found_page   = "404.html"   # 404時に返すカスタムエラーページ
  }

  uniform_bucket_level_access = true # バケット単位のアクセス制御を有効化
  force_destroy               = true # destroy時にオブジェクトごと削除可能にする
}

# バケットを誰でも読めるように公開する（静的サイト公開に必須）
resource "google_storage_bucket_iam_member" "public_read" {
  bucket = google_storage_bucket.website.name # 対象のバケット
  role   = "roles/storage.objectViewer"       # オブジェクト閲覧権限
  member = "allUsers"                         # 全ユーザー（=インターネット全体に公開）
}

# index.htmlをバケットにアップロード
resource "google_storage_bucket_object" "index" {
  name         = "index.html"                       # バケット内でのオブジェクト名
  bucket       = google_storage_bucket.website.name # アップロード先バケット
  source       = "${path.module}/../site/index.html"
  content_type = "text/html"
}

# 404.htmlをバケットにアップロード
resource "google_storage_bucket_object" "error_page" {
  name         = "404.html"
  bucket       = google_storage_bucket.website.name
  source       = "${path.module}/../site/404.html"
  content_type = "text/html"
}

# ============================================================
# 2. HTTP(S) Load Balancer + Cloud CDN
#
# GCPのLBは以下の4つのリソースで構成される（AWSのALBに相当）:
#   Global Address → Forwarding Rule → Target Proxy → URL Map → Backend
# ============================================================

# LBに割り当てる静的グローバルIPアドレス
resource "google_compute_global_address" "website" {
  name = "website-ip"
}

# Backend Bucket: GCSバケットをLBのバックエンドとして登録
resource "google_compute_backend_bucket" "website" {
  name        = "website-backend"
  bucket_name = google_storage_bucket.website.name
  enable_cdn  = true # Cloud CDNを有効化

  cdn_policy {
    cache_mode       = "CACHE_ALL_STATIC" # 静的コンテンツをすべてキャッシュ
    default_ttl      = 3600               # デフォルトTTL（秒）= 1時間
    client_ttl       = 300                # ブラウザキャッシュTTL = 5分
    max_ttl          = 86400              # 最大TTL = 24時間
    negative_caching = true               # 404等のエラーレスポンスもキャッシュ
  }
}

# URL Map: URLパスとバックエンドのマッピング（ここでは全パスを1つのバックエンドに送る）
resource "google_compute_url_map" "website" {
  name            = "website-url-map"
  default_service = google_compute_backend_bucket.website.id
}

# Target HTTP Proxy: HTTPリクエストを受け取ってURL Mapに渡す
resource "google_compute_target_http_proxy" "website" {
  name    = "website-http-proxy"
  url_map = google_compute_url_map.website.id
}

# Forwarding Rule: IPアドレスとポートをTarget Proxyに紐付ける（AWSでいうListenerに近い）
resource "google_compute_global_forwarding_rule" "website" {
  name       = "website-forwarding-rule"
  target     = google_compute_target_http_proxy.website.id
  port_range = "80"
  ip_address = google_compute_global_address.website.address
}

# ============================================================
# 3. Cloud DNS（任意。独自ドメインを持っている場合のみ）
# ============================================================
# resource "google_dns_managed_zone" "website" {
#   name     = "website-zone"        # DNSゾーンの名前
#   dns_name = "example.com."        # 管理するドメイン（末尾のドットは必須）
# }
#
# resource "google_dns_record_set" "website_a" {
#   name         = "www.example.com."
#   managed_zone = google_dns_managed_zone.website.name
#   type         = "A"
#   ttl          = 300
#   rrdatas      = [google_compute_global_address.website.address]
# }
