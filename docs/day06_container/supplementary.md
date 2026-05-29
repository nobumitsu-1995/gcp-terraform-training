# Day 6 補足: Cloud Run / GCE / GKE の使い分け

## 比較表

| 観点 | Cloud Run | GCE | GKE |
| --- | --- | --- | --- |
| **抽象度** | サービス（=コンテナ + URL） | 仮想マシン | クラスタ + Pod |
| **起動単位** | リクエスト駆動 | 常時稼働 | Pod常時稼働（Job例外） |
| **スケール** | 自動 (0〜N) | 手動 (MIGで自動も可) | HPAで自動 |
| **コスト** | リクエスト課金 + vCPU秒 | 時間課金 | ノード時間課金 |
| **状態** | ステートレス推奨 | ステートフルOK | StatefulSet で可 |
| **デプロイ単位** | コンテナイメージ | OS + アプリ | Helm / kustomize |
| **学習コスト** | 低 | 中 | 高 |

## 選び方の指針

### Cloud Run を選ぶケース

- HTTPで叩かれるAPIサーバー、Webアプリ
- リクエストがバースト的に発生する（深夜は0でいい）
- ステートレス（DBやキャッシュは外部サービスを使う）
- マイクロサービスの1コンポーネント

### GCE を選ぶケース

- 特殊なOSパッケージや低レベル機能が必要（カーネルモジュール等）
- 常時稼働するワーカープロセス（バッチではない）
- レガシーアプリのリフト&シフト
- GPU等の特殊ハードウェアが必要

### GKE を選ぶケース

- 複数のサービスを連携させる複雑なマイクロサービス基盤
- Kubernetes エコシステムを活用したい（Istio, Knative等）
- すでにK8sの運用ノウハウがあるチーム
- マルチクラウドでの可搬性が必要

> 💡 **迷ったらまず Cloud Run** を試すのが2025年現在の定石です。Cloud Run で困ってからGKEに移行する流れが現実的。

---

## Cloud Run の重要な概念

### リビジョン

```
hello-app (Service)
  ├─ hello-app-00001-abc  ← v1 (100% traffic)
  ├─ hello-app-00002-def  ← v2 (0% traffic, ready to switch)
  └─ hello-app-00003-ghi  ← v3 (latest, deploying)
```

デプロイごとに新しいリビジョンが作られ、URL を維持したまま中身を切り替えられます。

```bash
# トラフィック分散（Blue/Green デプロイ）
gcloud run services update-traffic hello-app \
  --to-revisions=hello-app-00001-abc=90,hello-app-00002-def=10 \
  --region=asia-northeast1
```

### 環境変数の起源

| ソース | 設定方法 | 上書き |
| --- | --- | --- |
| `ENV` (Dockerfile) | ビルド時に固定 | 下記で上書き可 |
| Cloud Run の env 設定 | デプロイ時 (`--set-env-vars` or Terraform) | Cloud Run の優先 |
| Secret Manager 参照 | `value_source.secret_key_ref` | 機密情報用 |

### コールドスタート

`min_instance_count = 0` の場合、リクエストがない時間が続くとインスタンスが破棄され、次の最初のリクエストで起動コスト（数百ms〜数秒）が発生します。これを「コールドスタート」と呼びます。

対策:
- `min_instance_count = 1` で常時1インスタンス維持（課金発生）
- ベースイメージを軽量化（`node:20-slim`, `distroless` 等）
- 起動時の重い処理を遅延ロードに変える

---

## よくあるトラブル

| 症状 | 原因 |
| --- | --- |
| デプロイ後に `503` | コンテナが PORT 環境変数で listen していない |
| `Permission denied` (Pull時) | Cloud Run のサービスアカウントに `roles/artifactregistry.reader` が必要 |
| メモリ不足で落ちる | `--memory` を増やす（Node.js は512Mi推奨） |
| HTTPS リクエストが届かない | `--allow-unauthenticated` がない、または IAM で `allUsers` が許可されていない |
