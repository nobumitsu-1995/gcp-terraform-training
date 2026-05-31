# Day 0: 環境準備

研修開始前に、各自のmacOS環境で以下のセットアップを完了してください。所要時間は約30分です。

---

## このDayのゴール

- AWSアカウントを作成し、無料利用枠（Free Tier）を使える状態にする
- 日常操作用のIAMユーザー（または IAM Identity Center ユーザー）を用意する
- `aws` CLI と Terraform をインストールする
- 認証を済ませて、次のDayからすぐにハンズオンを始められる状態にする

---

## 1. AWSアカウントの作成

**必要なもの**: メールアドレス、クレジットカード（無料利用枠の範囲では基本的に課金されません）、電話番号（SMS/音声認証）

1. https://aws.amazon.com/free にアクセス
2. 「無料アカウントを作成」からメールアドレス・アカウント名を登録
3. 連絡先情報・支払い情報（クレジットカード）・本人確認（電話）を入力
4. サポートプランは「ベーシック（無料）」を選択

> 💡 GCPのような「$300クレジット」はありません。代わりに **12ヶ月間無料** と **常時無料** の枠（[Free Tier](https://aws.amazon.com/free/)）があります。枠を超えると課金されるため、ハンズオン後の後片付け（`terraform destroy`）が重要です。

最初に作られるのは **ルートユーザー**（メールアドレスでログインする最上位アカウント）です。ルートユーザーは強力すぎるため、**日常操作には使いません**（次の手順で作業用ユーザーを用意します）。

---

## 2. ルートユーザーの保護と作業用ユーザーの作成

セキュリティのベストプラクティスとして、ルートユーザーは保護し、普段は権限を絞ったユーザーで作業します。

1. **ルートユーザーにMFA（多要素認証）を設定する**
   - コンソール右上のアカウント名 →「セキュリティ認証情報」→「MFAを割り当てる」
2. **作業用ユーザーを用意する**（どちらか一方でOK）

**方法A: IAMユーザー（シンプル・研修向け）**

1. コンソールで「IAM」→「ユーザー」→「ユーザーを作成」
2. ユーザー名（例: `training-admin`）を入力
3. 権限は研修用途として `AdministratorAccess` ポリシーをアタッチ（※実務では最小権限に絞ります。Day 1で解説）
4. 作成後、「セキュリティ認証情報」タブで **アクセスキー** を発行し、控えておく

**方法B: IAM Identity Center（旧 AWS SSO・実務寄り）**

- 複数アカウント運用や短期トークンを使いたい場合はこちら。`aws configure sso` で設定します（Day 2で詳しく扱います）。

> 研修では **方法A（IAMユーザー + アクセスキー）** で十分です。

---

## 3. Homebrew のインストール（macOS）

```bash
# Homebrew がなければインストール
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

---

## 4. AWS CLI のインストール

```bash
# AWS CLI v2 のインストール
brew install awscli

# インストール確認
aws --version
```

---

## 5. Terraform のインストール

```bash
# HashiCorp の公式tapを追加
brew tap hashicorp/tap

# Terraform のインストール
brew install hashicorp/tap/terraform

# インストール確認
terraform version
```

---

## 6. 認証とプロファイル設定

手順2で発行したアクセスキーを使って、CLIの認証情報を設定します。

```bash
# 研修用の名前付きプロファイルを作成（対話式で入力）
aws configure --profile training
# AWS Access Key ID     [None]: ＜発行したアクセスキーID＞
# AWS Secret Access Key [None]: ＜発行したシークレットアクセスキー＞
# Default region name   [None]: ap-northeast-1     ← 東京リージョン
# Default output format [None]: json
```

```bash
# どのプロファイルを使うかをシェルに指定（ターミナルを開くたびに実行 or シェル設定に追記）
export AWS_PROFILE=training
```

> 💡 Terraform は環境変数 `AWS_PROFILE`（または `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`）の認証情報を自動で使います。プロファイルを切り替えれば、Terraform の向き先もそのまま切り替わります。

---

## 7. 動作確認

```bash
# 認証情報が正しく設定されているか確認（アカウントID・ユーザーARNが表示される）
aws sts get-caller-identity

# 現在のプロファイル設定を確認
aws configure list

# Terraform の動作確認
terraform version
```

`aws sts get-caller-identity` で自分のアカウントIDとユーザーが表示されれば認証OKです。

---

## チェックリスト

最終的に以下が完了していれば準備OKです。詳細は [checklist.md](./checklist.md) を参照。

- [ ] AWSアカウント作成・Free Tier利用可能
- [ ] ルートユーザーにMFA設定済み
- [ ] 作業用IAMユーザー作成・アクセスキー発行済み
- [ ] Homebrew インストール済み
- [ ] AWS CLI インストール・`aws configure` 済み
- [ ] Terraform インストール済み
- [ ] `aws sts get-caller-identity` が成功する
- [ ] `terraform version` が成功する

---

## 次のステップ

→ [Day 1: クラウドとAWSの基礎概念](../day01_cloud_basics/README.md)
