# Day 0 セットアップ チェックリスト

研修開始前に以下をすべて完了させてください。

---

## 1. アカウント関連

- [ ] メールアドレスを使って https://aws.amazon.com/free でAWSアカウントを作成した
- [ ] AWSマネジメントコンソール (https://console.aws.amazon.com) にログインできる
- [ ] 支払い情報（クレジットカード）を登録した
- [ ] ルートユーザーにMFA（多要素認証）を設定した

---

## 2. 作業用ユーザー

- [ ] 作業用のIAMユーザー（例: `training-admin`）を作成した
- [ ] 研修用途の権限（`AdministratorAccess` 等）をアタッチした
- [ ] アクセスキーID / シークレットアクセスキーを発行・控えた

---

## 3. ローカル環境（macOS）

- [ ] Homebrew がインストールされている (`brew --version`)
- [ ] AWS CLI v2 がインストールされている (`aws --version`)
- [ ] Terraform がインストールされている (`terraform version`)

---

## 4. 認証・設定

- [ ] `aws configure --profile training` で認証情報・リージョン(ap-northeast-1)を設定済み
- [ ] `export AWS_PROFILE=training` で使用プロファイルを指定した
- [ ] `aws configure list` で正しいプロファイル・リージョンが表示される

---

## 5. 動作確認

- [ ] `aws sts get-caller-identity` が成功し、自分のアカウントID・ユーザーARNが表示される
- [ ] `terraform version` が成功する
- [ ] 簡単なTerraform（S3バケット作成など）でplan/applyが試せる（任意）

---

## 完了したら

→ Day 1 へ進んでください。
