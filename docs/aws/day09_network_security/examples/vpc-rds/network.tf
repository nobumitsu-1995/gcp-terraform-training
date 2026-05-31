data "aws_availability_zones" "available" {
  state = "available"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "main-vpc" }
}

# プライベートサブネット（RDSは複数AZが必須のため2つ作る）
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = { Name = "private-${count.index}" }
}

# RDS 用のセキュリティグループ（VPC内からの 5432 のみ許可）
resource "aws_security_group" "rds" {
  name        = "rds-sg"
  description = "Allow PostgreSQL from within the VPC"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "PostgreSQL from VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# DBサブネットグループ（複数AZのサブネットを束ねてRDSを配置）
resource "aws_db_subnet_group" "main" {
  name       = "main-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id
}
