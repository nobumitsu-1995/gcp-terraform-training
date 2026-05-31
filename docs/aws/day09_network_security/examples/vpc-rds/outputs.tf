# 注意: パスワードは output しないこと（state に平文で残る）
output "db_endpoint" {
  value       = aws_db_instance.main.address
  description = "RDS のエンドポイント（VPC内からのみ到達可能）"
}

output "db_subnet_group" {
  value       = aws_db_subnet_group.main.name
  description = "DBサブネットグループ名"
}

output "vpc_id" {
  value       = aws_vpc.main.id
  description = "作成されたVPCのID"
}

output "secret_arn" {
  value       = aws_secretsmanager_secret.db_password.arn
  description = "DBパスワードのSecrets Manager ARN"
}
