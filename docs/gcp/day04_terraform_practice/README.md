# Day 4: Terraform実践パターン — チーム開発と複数環境への道

**ゴール**: Day 3の基本から一歩進み、チームでの開発や複数環境（開発/本番）の管理に不可欠な実践パターンを習得する。

---

## Day 3からの課題

Day 3では、1つのディレクトリで個人のインフラを管理する方法を学びました。しかし、実務では次のような課題に直面します。

1.  **環境ごとの差異**: 開発環境と本番環境で、リソースの数やスペック、設定値を変えたい。どう管理すればいい？
2.  **コードの重複**: 似たようなリソース（例: 用途別のGCSバケット）をたくさん作りたいが、同じコードを何度もコピペしたくない。
3.  **チームでの共同作業**:
    - 他の人がどんなインフラを持っているか分からない。
    - 自分のPCが壊れたら、インフラの状態（State）も失われてしまう。
    - 複数人が同時に `apply` したら、インフラが壊れてしまいそう。

これらの課題を解決するのが、Day 4で学ぶ **変数分離・モジュール化・Remote Backend** です。

---

## 1. 変数で設定を分離する (`.tfvars`)

**課題**: 環境ごとの差異をどう管理するか？

**解決策**: 設定値をコードから分離し、環境ごとに切り替えられるようにする。

Terraformでは、`variables.tf` で変数を「宣言」し、`.tfvars` ファイルで値を「代入」する役割分担が基本です。

- **`variables.tf`**: 変数の型や説明、デフォルト値を定義する「設計図」。
- **`.tfvars`**: 変数に具体的な値を代入する「設定ファイル」。

#### 環境ごとの `.tfvars` ファイル

実務では、環境ごとに `tfvars` ファイルを用意します。

- `terraform.tfvars`: 全環境で共通のデフォルト値（Git管理しないことが多い）。
- `dev.tfvars`: 開発環境用の値。
- `stg.tfvars`: ステージング環境用の値。
- `prod.tfvars`: 本番環境用の値。

#### ハンズオン: 環境を切り替えて `plan` する

サンプルコード: [examples/multi-bucket/](./examples/multi-bucket/)

Day3と同様に、TerraformがGCPプロジェクトIDを認識できるように環境変数を設定しておきます。

```bash
# ターミナルで環境変数を設定
export TF_VAR_project_id=$GOOGLE_CLOUD_PROJECT

# サンプルコードのディレクトリへ移動
cd docs/gcp/day04_terraform_practice/examples/multi-bucket

# 1. 開発環境用の設定でplan
# -var-file オプションで読み込むファイルを指定
terraform plan -var-file="dev.tfvars"

# 2. 本番環境用の設定でplan
terraform plan -var-file="prod.tfvars"
```

`plan` の結果、作成されるバケット名や設定が `dev.tfvars` と `prod.tfvars` の内容に応じて変化することを確認しましょう。これにより、**同じコードで異なる環境を安全に管理**できます。

> 💡 **変数の優先順位**: Terraformは様々な場所から変数を読み込みますが、優先順位があります。
> **高**: `-var` オプション > `*.auto.tfvars` > `terraform.tfvars` > `variables.tf` の `default` : **低**

---

## 2. コードを部品化する（モジュール）

**課題**: 同じようなコードのコピペをやめたい。

**解決策**: 再利用可能なコードを「モジュール」という部品に切り出す。

モジュール化には多くのメリットがあります。
- **DRY (Don't Repeat Yourself)**: コードの重複をなくし、修正箇所を1つに集約できる。
- **再利用性**: プロジェクトやチームをまたいで、標準化されたインフラ部品を使いまわせる。
- **見通しの改善**: `main.tf` は「どんな部品を」「どう組み合わせるか」という全体像の記述に集中でき、詳細な実装はモジュール内に隠蔽される。

#### ハンズオン: モジュールを呼び出す

`main.tf` から、`./modules/gcs_bucket` というディレクトリにあるモジュールを呼び出しています。

```hcl
# main.tf (呼び出し元)

# "data" という名前で gcs_bucket モジュールを呼び出す
module "data_bucket" {
  source = "./modules/gcs_bucket" # モジュールのパス

  # モジュール内の変数に値を渡す
  bucket_name        = "${var.project_id}-data-bucket"
  location           = var.region
  versioning_enabled = true
}

# "logs" という名前で gcs_bucket モジュールをもう一度呼び出す
module "logs_bucket" {
  source = "./modules/gcs_bucket"

  bucket_name        = "${var.project_id}-logs-bucket"
  location           = var.region
  versioning_enabled = false
}
```

`module` ブロックは、関数を呼び出すように、別の場所にあるTerraformコードの塊をインスタンス化します。`source` で部品の場所を指定し、引数のように値を渡すことで、**同じ部品から設定の違うリソースをいくつも作成**できます。

---

## 3. Stateをチームで共有する（Remote Backend）

**課題**: チームでの安全な共同作業を実現したい。

**解決策**: Stateファイルをローカルではなく、全員がアクセスできる共有ストレージ（GCSなど）で管理する。

ローカルの `terraform.tfstate` ファイルには、チーム開発において致命的な問題があります。
- **Stateの不整合**: 各自がローカルで `apply` すると、誰がどんなインフラを持っているか分からなくなる。
- **Stateの消失**: PCが壊れると、インフラの状態も分からなくなる。
- **競合**: 複数人が同時に `apply` すると、Stateファイルが壊れ、インフラが予期せぬ状態になる可能性がある。

Remote Backendはこれらの問題を解決します。
- **Stateの共有**: GCSなどにStateを置くことで、チーム全員が常に最新のインフラ状態を参照できる。
- **Stateのロック**: 誰かが `apply` を実行すると、Stateファイルが自動的にロックされる。他の人はロックが解除されるまで `apply` できなくなり、競合を防げる。

#### ハンズオン: Remote Backend を設定する

1.  **State保存用のGCSバケットを作成**
    ```bash
    # 環境変数 $GOOGLE_CLOUD_PROJECT を使って、グローバルで一意なバケット名を作成
    gsutil mb -l asia-northeast1 gs://${GOOGLE_CLOUD_PROJECT}-tfstate/
    ```

2.  **バックエンド設定を記述**
    `terraform.tf` に `backend` ブロックを追加します。
    エディタで `terraform.tf` を開き、`bucket` の値を、先ほど作成したご自身のバケット名（例: `my-gcp-project-123-tfstate`）に書き換えてください。

    > ⚠️ **なぜ手動で書き換えるの？**
    > Terraformの `backend` ブロックは、変数が評価されるよりも前に読み込まれるため、残念ながら `${var.project_id}` のような変数を使うことができません。そのため、この部分だけは環境に合わせて手動で設定する必要があります。

    ```hcl
    # terraform.tf
    terraform {
      backend "gcs" {
        bucket = "YOUR_PROJECT_ID-tfstate" # ★★★ この行を自分のプロジェクトIDに書き換える ★★★
        prefix = "gcp/day04/multi-bucket"         # バケット内でStateを置くパス
      }
    }
    ```

3.  **`terraform init` でバックエンドを初期化**
    `backend` ブロックを修正したら、必ず `init` を再実行します。

    ```bash
    terraform init
    ```
    ローカルに `terraform.tfstate` ファイルが存在する場合、リモートに移行するか尋ねられます。`yes` と入力すると、StateがGCSにアップロードされます。これ以降、StateはGCS上で管理されます。

---

## 4. 繰り返しリソースを定義する (`for_each`)

**課題**: リストやマップを元に、複数のリソースを動的に作りたい。

**解決策**: `for_each` を使って、コードのコピペなしにリソースを繰り返し定義する。

`for_each` は、`set` または `map` の各要素に対してリソースやモジュールを1つずつ作成します。

```hcl
# main.tf

# ユーザー名のリスト
variable "users" {
  type    = set(string)
  default = ["alice", "bob", "charlie"]
}

# 各ユーザー専用のバケットを作成する
module "user_buckets" {
  for_each = var.users # 集合の各要素に対してモジュールを呼び出す

  source      = "./modules/gcs_bucket"
  bucket_name = "${var.project_id}-user-${each.key}" # each.key に "alice", "bob"... が入る
  location    = var.region
}
```

`for_each` を使うと、リストの要素数が変わっても、Terraformが自動でリソースの追加・削除を判断してくれます。

> 💡 **`count` と `for_each` の違い**: 以前は `count` が使われていましたが、リストの途中の要素を削除すると、以降のすべてのリソースが再作成されるという問題がありました。`for_each` はキーに基づいてリソースを管理するため、このような問題が起きません。**原則として `for_each` を使いましょう。**

---

## 次のステップ

これらの実践パターンを使いこなし、次のワークショップに挑戦しましょう！

→ [Day 5: Level 1 ワークショップ — GCS静的サイト + LB + CDN](../day05_workshop_level1/README.md)