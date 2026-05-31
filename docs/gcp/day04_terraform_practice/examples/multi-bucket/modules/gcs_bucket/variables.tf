variable "bucket_name" {
  description = "GCSバケット名（グローバルで一意である必要がある）"
  type        = string
}

variable "location" {
  description = "バケットのロケーション"
  type        = string
}

variable "versioning_enabled" {
  description = "バージョニングを有効化するか"
  type        = bool
  default     = false
}

variable "lifecycle_age_days" {
  description = "何日経過したオブジェクトを自動削除するか"
  type        = number
  default     = 30
}
