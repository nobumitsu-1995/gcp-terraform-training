resource "aws_secretsmanager_secret" "db_password" {
  name                    = "level3-db-password"
  recovery_window_in_days = 0 # destroy時に即削除（再applyしやすくするため）
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = var.db_password
}
