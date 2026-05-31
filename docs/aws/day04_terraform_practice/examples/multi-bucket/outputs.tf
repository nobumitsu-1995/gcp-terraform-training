output "bucket_names" {
  value = [for b in module.buckets : b.bucket_id]
}
