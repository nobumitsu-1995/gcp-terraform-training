# Day 0 セットアップ動作確認チェックリスト

研修開始前に、以下のコマンドを上から順に実行し、すべて期待通りの結果が得られることを確認してください。

## 1. gcloud CLI

```bash
gcloud version
```

期待される出力例:
```
Google Cloud SDK 458.0.1
bq 2.0.99
core 2024.01.05
gcloud-crc32c 1.0.0
gsutil 5.27
```

## 2. gcloud 認証状態

```bash
gcloud auth list
```

期待される出力例:
```
                  Credentialed Accounts
ACTIVE  ACCOUNT
*       you@example.com

To set the active account, run:
    $ gcloud config set account `ACCOUNT`
```

## 3. アプリケーションデフォルト認証

```bash
gcloud auth application-default print-access-token
```

トークン文字列が表示されればOK（Terraform が利用する認証情報）。

## 4. Terraform

```bash
terraform version
```

期待される出力例:
```
Terraform v1.6.5
on darwin_arm64
```

## 5. Docker

```bash
docker version
docker run --rm hello-world
```

`hello-world` コンテナが正常に起動して `Hello from Docker!` が表示されればOK。

## 6. drawio（構成図ビューア）

任意ですが、Level 1〜3 ワークショップの構成図を快適に閲覧・編集するために推奨します。

**VS Code 利用者:**

```bash
# 拡張機能をインストール
code --install-extension hediet.vscode-drawio

# インストール確認
code --list-extensions | grep -i drawio
# hediet.vscode-drawio と表示されればOK
```

インストール後、`docs/day05_workshop_level1/architecture.drawio` を VS Code で開き、ビジュアルエディタが表示されればOK。

**VS Code 以外:**

- ブラウザ版: https://app.diagrams.net/ で「Device」から `.drawio` ファイルを開けるか確認
- デスクトップ版 (macOS): `brew install --cask drawio` → アプリケーションフォルダから起動

## 7. プロジェクト疎通テスト

研修用のプロジェクトを作成済みであれば、以下のコマンドで簡単な疎通確認ができます。

```bash
# 現在のアクティブな設定
gcloud config list

# プロジェクトのAPIサービス一覧
gcloud services list --enabled --limit=5
```

## トラブルシューティング

### `gcloud: command not found`

`~/.zshrc` への source 設定が反映されていない可能性があります。新しいターミナルを開き直すか、`source ~/.zshrc` を再実行してください。

### `Your default credentials were not found`

Terraform から呼ばれた場合に出るエラーです。`gcloud auth application-default login` を実行してください。

### Docker Desktop が起動しない (Apple Silicon Mac)

Docker Desktop の設定で「Use Rosetta for x86/amd64 emulation on Apple Silicon」を有効化すると安定する場合があります。
