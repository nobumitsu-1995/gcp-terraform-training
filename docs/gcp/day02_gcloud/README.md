# Day 2: GCPコンソール操作・gcloud CLI

**ゴール**: GUIとCLIの両方でGCPを操作できる。複数アカウント/プロジェクトの切り替え方法も理解する。

---

## 1. 基本セットアップ

```bash
# 初期設定（ブラウザでログイン→プロジェクト選択→リージョン設定）
gcloud init
```

`gcloud init` で対話的に以下が設定されます:

- ログインアカウント
- アクティブなプロジェクト
- デフォルトのリージョン / ゾーン

---

## 2. gcloud configuration による複数アカウント・プロジェクト管理

実務では「個人アカウントと社用アカウント」「本番プロジェクトと開発プロジェクト」など、複数の認証情報やプロジェクトを切り替える場面が頻繁にあります。gcloud では `configuration` でこれを管理します。

完全なコマンド例は [examples/01-configuration.sh](./examples/01-configuration.sh) を参照。

```bash
# --- 現在の設定を確認 ---
gcloud config configurations list

# --- 研修用の configuration を新規作成 ---
gcloud config configurations create training

# --- 研修用アカウントでログイン ---
gcloud auth login
gcloud auth application-default login   # Terraform用の認証も忘れずに

# --- プロジェクト・リージョンを設定 ---
gcloud config set project YOUR_TRAINING_PROJECT_ID
gcloud config set compute/region asia-northeast1
gcloud config set compute/zone asia-northeast1-a

# --- configurationの切り替え ---
gcloud config configurations activate default
gcloud config configurations activate training
```

### configuration のポイント

- `configuration` はアカウント・プロジェクト・リージョンのセットを名前付きで保存する仕組み
- `activate` で瞬時に切り替え可能。`gcloud init` を再実行する必要はない
- `CLOUDSDK_ACTIVE_CONFIG` 環境変数でシェル単位の切り替えもできる（別ターミナルで別configを同時利用可能）
- Terraform は `gcloud auth application-default login` の認証情報を使うため、configurationを切り替えたら `application-default login` も再実行すること

```bash
# シェル単位で別configを使う（ターミナルAとBで別プロジェクトを同時操作）
export CLOUDSDK_ACTIVE_CONFIG=training
```

> 💡 **研修専用アカウントがない場合**: 同一アカウント内でプロジェクトだけ分ければ十分です。
>
> ```bash
> gcloud config configurations create training
> gcloud config set account you@gmail.com
> gcloud config set project training-project
> gcloud config set compute/region asia-northeast1
> ```

---

## 3. APIの有効化とGCSの基本操作

研修で使うAPIを一括有効化し、GCSの基本操作で gcloud / gsutil の感覚をつかみます。

実行スクリプト: [examples/02-enable-apis.sh](./examples/02-enable-apis.sh), [examples/03-gcs-basics.sh](./examples/03-gcs-basics.sh)

```bash
# 以降の研修で使うAPIを一括有効化
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
```

```bash
# GCSバケットの作成・操作（CLIの感覚をつかむ）
gsutil mb -l asia-northeast1 gs://${GOOGLE_CLOUD_PROJECT}-test/
echo "<h1>Hello GCP</h1>" > index.html
gsutil cp index.html gs://${GOOGLE_CLOUD_PROJECT}-test/
gsutil ls gs://${GOOGLE_CLOUD_PROJECT}-test/

# 後片付け
gsutil rm -r gs://${GOOGLE_CLOUD_PROJECT}-test/
```

---

## 確認課題

1. 研修用の `configuration` を作成して切り替えられること。
2. gcloud CLI でバケットの作成 → ファイルアップロード → 削除を一通り実行できること。

---

## 補足

- gcloud / gsutil チートシート: [supplementary.md](./supplementary.md)

---

## 次のステップ

→ [Day 3: Terraform入門](../day03_terraform_intro/README.md)
