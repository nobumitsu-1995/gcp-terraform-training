data "aws_caller_identity" "current" {}

module "buckets" {
  source = "./modules/s3_bucket"

  for_each = toset([
    for i in range(var.bucket_count) : "bucket-${i}"
  ])

  name          = "${data.aws_caller_identity.current.account_id}-${var.environment}-${each.key}"
  force_destroy = true
}
