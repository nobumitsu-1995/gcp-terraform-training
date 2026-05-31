# Day 0: 環境準備

研修開始前に以下のセットアップを完了してください。所要時間は30分程度です。

> ⚠️ Day 0が完了していないと、Day 2以降のハンズオンが進められません。研修初日までに必ず終わらせてください。

---

## 0-1. GCPアカウントの作成と無料トライアルの有効化

**必要なもの**: Googleアカウント（Gmail等）、クレジットカード（課金は発生しません）

1. https://cloud.google.com/free にアクセスする
2. 「無料で開始」をクリックし、Googleアカウントでログインする
3. 国・組織情報・利用規約の同意を入力する
4. クレジットカード情報を登録する（本人確認用。無料トライアル期間中は自動課金されない）
5. 登録完了後、GCPコンソール（ https://console.cloud.google.com ）にアクセスできることを確認する

**確認ポイント**:

- コンソール上部に「無料トライアルの残り $300.00」などのクレジット残高が表示されていること
- 「お支払い」→「概要」で無料トライアルのステータスが有効であること

> ⚠️ 無料トライアル期間（90日間）が終了しても、明示的にアップグレードしない限り自動課金は発生しません。研修期間中はアップグレードしないでください。

---

## 0-2. gcloud CLI のインストール

```bash
# Homebrew でインストール
brew install --cask google-cloud-sdk

# シェルにパスと補完を通す（~/.zshrc に追加）
echo 'source "$(brew --prefix)/share/google-cloud-sdk/path.zsh.inc"' >> ~/.zshrc
echo 'source "$(brew --prefix)/share/google-cloud-sdk/completion.zsh.inc"' >> ~/.zshrc
source ~/.zshrc

# バージョン確認
gcloud version
# Google Cloud SDK 4xx.x.x 以上が表示されればOK

# ログイン（ブラウザが開く）
gcloud auth login

# アプリケーションデフォルト認証（Terraformが使う認証）
gcloud auth application-default login
```

> ⚠️ `gcloud auth login` と `gcloud auth application-default login` は別物です。前者は gcloud CLI 自体の認証、後者はTerraformなどのアプリケーションが使う認証情報です。**両方実行してください。**

---

## 0-3. Terraform CLI のインストール

```bash
# Homebrew でインストール
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# バージョン確認
terraform version
# Terraform v1.5.x 以上が表示されればOK
```

---

## 0-4. Docker Desktop のインストール

Day 6以降のコンテナハンズオンで使用します。

1. https://www.docker.com/products/docker-desktop/ からmacOS版をダウンロード
2. `.dmg` を開いてApplicationsにドラッグ
3. Docker Desktop を起動し、初期セットアップを完了する

```bash
docker version
# Client / Server 両方のバージョンが表示されればOK
```

---

## 0-5. drawio のセットアップ（任意・推奨）

Level 1〜3 ワークショップの構成図は `.drawio` 形式で配布しています。PNGプレビューも同梱していますが、編集したい / 細部をズームして確認したい場合は drawio で開いてください。

### 推奨: VS Code 拡張機能（マルチプラットフォーム対応）

VS Code 上で `.drawio` ファイルをそのまま開いて編集できます。追加のアプリインストールは不要です。

1. VS Code を開く
2. 拡張機能ビュー（`⌘+Shift+X`）で「Draw.io Integration」を検索
3. **Draw.io Integration** (`hediet.vscode-drawio`) をインストール
4. 任意の `.drawio` ファイル（例: `docs/day05_workshop_level1/architecture.drawio`）を開くとビジュアルエディタが起動する

```bash
# CLIからの一括インストールも可
code --install-extension hediet.vscode-drawio
```

> 💡 `.drawio.png` や `.drawio.svg` 形式で保存すると、PNGビューアでもそのまま閲覧でき、編集も可能なハイブリッド形式になります（必要な場合のみ）。

### VS Code 以外の場合

| 環境 | 推奨ツール | 入手先 |
| --- | --- | --- |
| ブラウザ（インストール不要） | diagrams.net Web版 | https://app.diagrams.net/ |
| macOS / Windows / Linux デスクトップ | drawio-desktop | https://github.com/jgraph/drawio-desktop/releases |
| JetBrains IDE（IntelliJ, GoLand 等） | Diagrams.net Integration プラグイン | Settings → Plugins で「Diagrams.net」を検索 |

**Web版の使い方** (一番手軽):

1. https://app.diagrams.net/ にアクセス
2. 「Device」を選択し、リポジトリ内の `.drawio` ファイル（例: `docs/day05_workshop_level1/architecture.drawio`）を開く
3. 編集後、`ファイル → 保存` でローカルに上書き保存される

**drawio-desktop**: ネット接続不要・オフライン編集が必要な場合はこちら。Homebrew でもインストール可能。

```bash
brew install --cask drawio
```

### 確認ポイント

- [ ] `docs/day05_workshop_level1/architecture.drawio` が VS Code / ブラウザ / デスクトップアプリのいずれかで開ける

---

## 0-6. 推奨ツール（任意）

- **VS Code + 拡張機能**: HashiCorp Terraform（HCL構文ハイライト・自動補完）、Google Cloud Code

---

## 0-7. セットアップ完了チェックリスト

詳細は [checklist.md](./checklist.md) を参照。

- [ ] GCPコンソール（ https://console.cloud.google.com ）にログインできる
- [ ] 無料トライアルのクレジット残高が表示されている
- [ ] `gcloud version` でバージョンが表示される
- [ ] `gcloud auth login` でログイン済み
- [ ] `gcloud auth application-default login` でアプリケーション認証済み
- [ ] `terraform version` で v1.5 以上が表示される
- [ ] `docker version` でDocker Engineのバージョンが表示される
- [ ] `.drawio` ファイルを開ける環境がある（VS Code 拡張 / Web版 / デスクトップアプリのいずれか）

---

## 次のステップ

→ [Day 1: クラウドとGCPの基礎概念](../day01_cloud_basics/README.md)
