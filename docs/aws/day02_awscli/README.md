# Day 2: AWSコンソール操作・AWS CLI

**ゴール**: GUIとCLIの両方でAWSを操作できる。複数アカウント/プロファイルの切り替え方法も理解する。

---

## 1. 基本セットアップ

Day 0 で `aws configure --profile training` を済ませていれば、CLIはすでに使える状態です。改めて設定する場合:

```bash
# 名前付きプロファイルを対話的に設定
aws configure --profile training
# AWS Access Key ID     [None]: ＜アクセスキーID＞
# AWS Secret Access Key [None]: ＜シークレットアクセスキー＞
# Default region name   [None]: ap-northeast-1
# Default output format [None]: json
```

設定は `~/.aws/credentials`（認証情報）と `~/.aws/config`（リージョン等）に保存されます。

> 💡 GCPの `gcloud init` に相当しますが、AWSはアカウント＝認証境界なので「プロジェクト選択」の概念はありません。代わりに **プロファイル** で認証情報とリージョンのセットを切り替えます。

---

## 2. 名前付きプロファイルによる複数アカウント・プロジェクト管理

実務では「個人アカウントと社用アカウント」「本番アカウントと開発アカウント」など、複数の認証情報を切り替える場面が頻繁にあります。AWS CLI では **名前付きプロファイル (named profile)** でこれを管理します。

完全なコマンド例は [examples/01-profiles.sh](./examples/01-profiles.sh) を参照。

```bash
# --- プロファイル一覧を確認 ---
aws configure list-profiles

# --- 研修用プロファイルを作成 ---
aws configure --profile training

# --- 本番用プロファイルを別途作成 ---
aws configure --profile prod

# --- コマンド単位で切り替え ---
aws s3 ls --profile training
aws s3 ls --profile prod

# --- シェル単位で切り替え（以降のコマンドすべてに適用） ---
export AWS_PROFILE=training
```

### プロファイルのポイント

- プロファイルは「アカウント認証情報 + リージョン + 出力形式」を名前付きで保存する仕組み
- `--profile NAME` でコマンド単位、`export AWS_PROFILE=NAME` でシェル単位に切り替えできる
- **Terraform は `AWS_PROFILE`（または `AWS_ACCESS_KEY_ID` 等の環境変数）の認証情報を自動で使う**ため、プロファイルを切り替えれば向き先もそのまま切り替わる
- ターミナルAとBで別アカウントを同時操作したい場合は、それぞれで `export AWS_PROFILE=...` を設定すればよい

```bash
# 別ターミナルで別アカウントを同時操作
export AWS_PROFILE=prod
```

### IAM Identity Center (SSO) を使う場合

複数アカウントを短期トークンで使い分ける実務環境では、長期アクセスキーの代わりにSSOを使います。

```bash
# SSO連携プロファイルを対話的に設定
aws configure sso --profile training-sso

# SSOでログイン（ブラウザが開く。トークンは数時間で失効）
aws sso login --profile training-sso
```

> 💡 **研修では名前付きプロファイル（アクセスキー）で十分です。** SSOは「アクセスキーを発行せず、短期トークンで運用したい」場合の選択肢として覚えておきましょう。

---

## 3. AWSには「API有効化」のステップはない

GCPでは利用前に `gcloud services enable ...` で各APIを有効化する必要がありますが、**AWSにはこの概念はありません**。アカウントを作った時点で各サービスは利用可能で、実際にリソースを作成した分だけ課金されます。

代わりに、Day 0 のように **IAMで「誰がどのサービスを操作できるか」を制御** します。「使えるかどうか」はAPI有効化ではなく、IAMポリシーで決まる、と理解してください。

---

## 4. S3の基本操作

S3の基本操作で aws CLI の感覚をつかみます。

実行スクリプト: [examples/02-s3-basics.sh](./examples/02-s3-basics.sh)

```bash
# バケット名はグローバルで一意である必要があるため、アカウントIDを接頭辞にする
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET="s3://${ACCOUNT_ID}-training-test"

# バケットの作成（東京リージョン）
aws s3 mb "${BUCKET}" --region ap-northeast-1

# ファイルをアップロード
echo "<h1>Hello AWS</h1>" > index.html
aws s3 cp index.html "${BUCKET}/"

# 一覧表示
aws s3 ls "${BUCKET}/"

# 後片付け（中身ごと削除）
aws s3 rb "${BUCKET}" --force
```

> 💡 `aws s3`（高レベルコマンド: cp/sync/mb/rb）と `aws s3api`（低レベル: バケットポリシー等の細かい操作）の2系統があります。普段の操作は `aws s3` で十分です。

---

## 確認課題

1. 研修用の名前付きプロファイルを作成し、`--profile` と `AWS_PROFILE` の両方で切り替えられること。
2. `aws sts get-caller-identity` で、想定通りのアカウント・ユーザーが表示されること。
3. AWS CLI でバケットの作成 → ファイルアップロード → 削除を一通り実行できること。

---

## 補足

- aws CLI チートシート: [supplementary.md](./supplementary.md)

---

## 次のステップ

→ [Day 3: Terraform入門](../day03_terraform_intro/README.md)
