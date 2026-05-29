output "bucket_name" {
  value       = google_storage_bucket.hello.name # apply後にターミナルに表示される値
  description = "作成されたGCSバケットの名前"
}

output "bucket_url" {
  value       = google_storage_bucket.hello.url # gs://BUCKET_NAME 形式のURL
  description = "GCSバケットのURL"
}
