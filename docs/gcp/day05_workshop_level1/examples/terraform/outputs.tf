output "website_ip" {
  value       = google_compute_global_address.website.address
  description = "ブラウザでこのIPにアクセスするとサイトが表示される"
}

output "bucket_url" {
  value       = "https://storage.googleapis.com/${google_storage_bucket.website.name}/index.html"
  description = "GCSバケットの直接URL（LBを介さない確認用）"
}
