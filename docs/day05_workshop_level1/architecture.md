# Level 1 構成図の解説

![Level 1 構成図](./architecture.png)

> 📐 編集可能な原本: [architecture.drawio](./architecture.drawio) — drawioで開いて構成を編集できます（セットアップ手順は [Day 0: 0-5. drawio のセットアップ](../day00_setup/README.md#0-5-drawio-のセットアップ任意推奨)）。

## リクエストフロー

```
[ユーザー (ブラウザ)]
        │ HTTP/HTTPS
        ▼
[Global Forwarding Rule] ← 静的IPアドレス (Global Address)
        │
        ▼
[Target HTTP Proxy]
        │
        ▼
[URL Map] (パスベースのルーティング)
        │
        ▼
[Backend Bucket] (Cloud CDN 有効化)
        │ (キャッシュ miss 時)
        ▼
[Cloud Storage バケット]
        ├── index.html
        └── 404.html
```

## 各コンポーネントの役割

### Cloud Storage（GCS）

HTMLファイルの実体を保管するオブジェクトストレージ。バケットに「静的Webサイト設定」を有効化し、`main_page_suffix` と `not_found_page` を指定することで、ディレクトリのルート（`/`）や存在しないパスに対するレスポンスを定義できます。

`uniform_bucket_level_access = true` でバケット単位のアクセス制御に統一し、`allUsers` プリンシパルに `roles/storage.objectViewer` を付与することでインターネット公開します。

### Backend Bucket + Cloud CDN

`google_compute_backend_bucket` は「GCSバケットをLBのバックエンドにする」リソースです。`enable_cdn = true` を指定するだけで Cloud CDN によるエッジキャッシュが有効になります。

CDN ポリシーで以下を制御:

| 設定 | 意味 |
| --- | --- |
| `cache_mode = "CACHE_ALL_STATIC"` | 静的コンテンツ（画像、CSS、JS、HTML等）をすべてキャッシュ |
| `default_ttl = 3600` | デフォルトキャッシュ期間（1時間） |
| `client_ttl = 300` | ブラウザ側のキャッシュ期間（5分） |
| `max_ttl = 86400` | 最大キャッシュ期間（24時間） |
| `negative_caching = true` | 404 などのエラーレスポンスもキャッシュする |

### HTTP(S) Load Balancer（4リソース構成）

GCPのLBは AWS の ALB と違って **複数の Terraform リソースに分解されている** のが特徴です。

- `google_compute_global_address`: グローバルな静的IPv4アドレス
- `google_compute_global_forwarding_rule`: IPとポートを listen するエントリポイント
- `google_compute_target_http_proxy`: HTTP プロトコルを処理する Proxy（HTTPS にする場合は `target_https_proxy` を使う）
- `google_compute_url_map`: パスベースルーティングを定義（今回は全パスを1つのバックエンドへ送る）

### Cloud DNS（任意）

独自ドメインを持っている場合は `google_dns_managed_zone` でゾーンを作り、`google_dns_record_set` でLBのIPにAレコードを向けます。本研修では省略可能（IP直アクセスで動作確認できる）。

---

## 課金が発生するリソース

| リソース | 課金単位 | 目安 |
| --- | --- | --- |
| Global Address | 静的IP保持時間 | 数時間で数円 |
| Forwarding Rule / LB | 時間課金 | $1〜3 / 日 |
| Cloud CDN | キャッシュHit + データ転送 | テスト程度なら数円 |

> ⚠️ LBは時間課金のため、検証後は必ず `terraform destroy` してください。
