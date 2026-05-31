terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

variable "region" {
  type    = string
  default = "ap-northeast-1"
}

variable "image" {
  type        = string
  description = "Container image URI in ECR (e.g. <acct>.dkr.ecr.ap-northeast-1.amazonaws.com/hello-repo:v1)"
}

# ECR リポジトリ
resource "aws_ecr_repository" "repo" {
  name         = "hello-repo"
  force_delete = true
}

# App Runner が ECR からイメージを取得するためのアクセスロール
resource "aws_iam_role" "apprunner_ecr" {
  name = "hello-apprunner-ecr-access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "build.apprunner.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "apprunner_ecr" {
  role       = aws_iam_role.apprunner_ecr.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

# App Runner サービス
resource "aws_apprunner_service" "hello" {
  service_name = "hello-app"

  source_configuration {
    authentication_configuration {
      access_role_arn = aws_iam_role.apprunner_ecr.arn
    }

    image_repository {
      image_identifier      = var.image
      image_repository_type = "ECR"

      image_configuration {
        port = "8080"
      }
    }

    auto_deployments_enabled = false
  }

  instance_configuration {
    cpu    = "1024" # 1 vCPU
    memory = "2048" # 2 GB
  }
}

output "service_url" {
  value       = "https://${aws_apprunner_service.hello.service_url}"
  description = "Public URL of the App Runner service"
}
