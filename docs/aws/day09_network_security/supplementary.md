# Day 9 補足: セキュリティのベストプラクティス

## 1. 最小権限の原則（Principle of Least Privilege）

IAMロールには「必要最小限」の権限だけを付与します。

```hcl
# ❌ 悪い例: 強すぎる権限
resource "aws_iam_role_policy_attachment" "bad" {
  role       = aws_iam_role.app.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess" # 全権限
}

# ✅ 良い例: 必要なアクション・リソースだけ
resource "aws_iam_role_policy" "good" {
  name = "read-one-secret"
  role = aws_iam_role.app.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
      Resource = aws_secretsmanager_secret.db_password.arn # この1つだけ
    }]
  })
}
```

## 2. Secrets Manager の活用

```hcl
resource "aws_secretsmanager_secret" "db_password" {
  name = "db-password"
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = var.db_password # 変数経由で渡す（tfvarsは.gitignore）
}
```

アプリ（Lambda / ECS）からは、実行ロールに `secretsmanager:GetSecretValue` を与えて実行時に取得します。App Runner や ECS では環境変数のシークレット参照として直接注入できます。

## 3. ネットワークセキュリティ

### プライベート配置の徹底

```
[インターネット]
      │
      ▼
[ALB / CloudFront] ← パブリックなのはここだけ
      │
      ▼
[ECS / Lambda] ← プライベートサブネット
      │
      ▼
[RDS] ← プライベート（publicly_accessible = false）
```

### セキュリティグループ（ステートフル）

```hcl
resource "aws_security_group" "rds" {
  name   = "rds-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "PostgreSQL from app SG only"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    # CIDRではなく「アプリのSG」だけを許可するのがより安全
    security_groups = [aws_security_group.app.id]
  }
}
```

> 💡 セキュリティグループは戻りトラフィックを自動許可（ステートフル）。サブネット全体に効かせたい・拒否ルールが必要なときはネットワークACL（ステートレス）を併用します。

## 4. IAMの監査

```bash
# ユーザー一覧
aws iam list-users

# 特定ユーザーにアタッチされたポリシー
aws iam list-attached-user-policies --user-name alice

# ロールの権限を確認
aws iam list-attached-role-policies --role-name app-secret-reader

# 誰が何をしたか（CloudTrailを有効化しておく）
aws cloudtrail lookup-events --max-results 10
```

## 5. その他のベストプラクティス

| 項目 | 推奨 |
| --- | --- |
| 長期アクセスキー | 可能な限り使わない（IAMロール / IAM Identity Center を使う） |
| 監査ログ | CloudTrail を有効化 |
| 暗号化 | デフォルトで保存時暗号化。鍵を自前管理するなら KMS (CMK) |
| 多要素認証 | ルートユーザー・管理者には必須 |
| ガードレール | 組織全体は AWS Organizations の SCP で制御 |
