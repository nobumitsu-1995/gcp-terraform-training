# カスタムモードVPC
resource "google_compute_network" "main" {
  name                    = "microservices-vpc"
  auto_create_subnetworks = false
}

# メインサブネット
resource "google_compute_subnetwork" "main" {
  name                     = "main-subnet"
  ip_cidr_range            = "10.0.1.0/24"
  region                   = var.region
  network                  = google_compute_network.main.id
  private_ip_google_access = true
}

# サーバーレスVPCコネクタ: Cloud Run → Cloud SQL接続を仲介
resource "google_vpc_access_connector" "main" {
  name          = "vpc-connector"
  region        = var.region
  network       = google_compute_network.main.name
  ip_cidr_range = "10.8.0.0/28" # /28 = 16個
  min_instances = 2
  max_instances = 3
}

# プライベートサービス接続（Cloud SQLにプライベートIPで接続するために必要）
resource "google_compute_global_address" "private_ip" {
  name          = "private-ip-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.main.id
}

resource "google_service_networking_connection" "private_vpc" {
  network                 = google_compute_network.main.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip.name]
}
