data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "hello" {
  bucket        = "${data.aws_caller_identity.current.account_id}-hello-terraform"
  force_destroy = true
}
