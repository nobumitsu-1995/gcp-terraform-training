data "aws_caller_identity" "current" {}

locals {
  bucket_name = "${data.aws_caller_identity.current.account_id}-static-site"
}

# 静的ファイルの配置先（非公開バケット）
resource "aws_s3_bucket" "site" {
  bucket        = local.bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket = aws_s3_bucket.site.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 静的ファイルをアップロード
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.site.id
  key          = "index.html"
  source       = "../site/index.html"
  content_type = "text/html"
  etag         = filemd5("../site/index.html")
}

resource "aws_s3_object" "not_found" {
  bucket       = aws_s3_bucket.site.id
  key          = "404.html"
  source       = "../site/404.html"
  content_type = "text/html"
  etag         = filemd5("../site/404.html")
}

# CloudFront が S3 を読むための Origin Access Control (OAC)
resource "aws_cloudfront_origin_access_control" "site" {
  name                              = "${local.bucket_name}-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "site" {
  enabled             = true
  default_root_object = "index.html"
  comment             = "Level 1 static site"
  price_class         = "PriceClass_200"

  origin {
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id                = "s3-site"
    origin_access_control_id = aws_cloudfront_origin_access_control.site.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-site"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    # AWS マネージドキャッシュポリシー "CachingOptimized"
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  # 存在しないオブジェクトは 404.html を返す
  custom_error_response {
    error_code         = 403
    response_code      = 404
    response_page_path = "/404.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 404
    response_page_path = "/404.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# このCloudFrontディストリビューションからのみS3読み取りを許可
resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowCloudFrontRead"
      Effect    = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.site.arn}/*"
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = aws_cloudfront_distribution.site.arn
        }
      }
    }]
  })
}
