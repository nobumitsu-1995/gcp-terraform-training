output "api_gateway_url" {
  value       = "https://${google_api_gateway_gateway.quickbite.default_hostname}"
  description = "API GatewayのHTTPSエンドポイント"
}

output "cloud_run_urls" {
  value = {
    order_svc      = google_cloud_run_v2_service.order_svc.uri
    processing_svc = google_cloud_run_v2_service.processing_svc.uri
    notify_svc     = google_cloud_run_v2_service.notify_svc.uri
  }
  description = "各Cloud Runサービスの直接URL"
}

output "db_private_ip" {
  value       = google_sql_database_instance.main.private_ip_address
  description = "Cloud SQL のプライベートIP"
}
