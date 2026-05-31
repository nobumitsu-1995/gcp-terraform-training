# RDS インスタンス（PostgreSQL・プライベート）
resource "aws_db_instance" "main" {
  identifier        = "main-instance"
  engine            = "postgres"
  engine_version    = "15"
  instance_class    = "db.t3.micro" # 12ヶ月無料枠の対象
  allocated_storage = 20

  db_name  = "appdb"
  username = "appuser"
  password = var.db_password # Secrets Manager にも保管する

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false # パブリックIPを持たせない（VPC内のみ）

  multi_az                = false # HAにするなら true（課金増）
  backup_retention_period = 1
  skip_final_snapshot     = true  # destroy時にスナップショットを残さない（研修用）
  deletion_protection     = false # 本番では true 推奨
}
