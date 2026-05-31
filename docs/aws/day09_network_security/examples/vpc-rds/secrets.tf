# DBパスワードを Secrets Manager に保管
resource "aws_secretsmanager_secret" "db_password" {
  name                    = "db-password"
  recovery_window_in_days = 0 # destroy時に即削除（研修で再applyしやすくするため）
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = var.db_password # tfvarsや環境変数経由で渡す
}

# アプリ用ロール（Lambda等がassumeしてシークレットを読む想定）
resource "aws_iam_role" "app" {
  name = "app-secret-reader"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# このシークレットの読み取り権限だけを付与（最小権限）
resource "aws_iam_role_policy" "app_secret" {
  name = "read-db-secret"
  role = aws_iam_role.app.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
      Resource = aws_secretsmanager_secret.db_password.arn
    }]
  })
}
