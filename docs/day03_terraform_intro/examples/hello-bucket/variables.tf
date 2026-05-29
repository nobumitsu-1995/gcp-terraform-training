variable "project_id" {
  description = "GCPプロジェクトID" # terraform plan時に表示される説明文
  type        = string             # 文字列型（必須入力）
}

variable "region" {
  description = "デフォルトリージョン"
  type        = string
  default     = "asia-northeast1" # デフォルト値（省略時はこの値が使われる）
}
