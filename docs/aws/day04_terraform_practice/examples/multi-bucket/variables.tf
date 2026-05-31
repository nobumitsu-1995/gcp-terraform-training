variable "region" {
  type    = string
  default = "ap-northeast-1"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "bucket_count" {
  type    = number
  default = 3
}
