variable "name" {
  type        = string
  description = "Bucket name"
}

variable "force_destroy" {
  type    = bool
  default = false
}
