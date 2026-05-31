output "site_url" {
  value       = "https://${aws_cloudfront_distribution.site.domain_name}/"
  description = "Access the site at this CloudFront URL"
}

output "bucket_name" {
  value = aws_s3_bucket.site.bucket
}
