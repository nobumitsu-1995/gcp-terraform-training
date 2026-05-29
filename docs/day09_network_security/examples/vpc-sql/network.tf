# カスタムモードVPC（AWSでいう VPC）
resource "google_compute_network" "main" {
  name                    = "training-vpc"
  auto_create_subnetworks = false # サブネットを手動で作成する（推奨）
}

# サブネット（AWSでいう Subnet）
resource "google_compute_subnetwork" "main" {
  name          = "main-subnet"
  ip_cidr_range = "10.0.1.0/24" # IPアドレス範囲（256個）
  region        = var.region
  network       = google_compute_network.main.id

  private_ip_google_access = true # Google APIへのプライベートアクセスを許可
}

# プライベートサービス接続（Cloud SQLにプライベートIPで接続するために必要）
resource "google_compute_global_address" "private_ip" {
  name          = "private-ip-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16 # /16 のIP範囲を確保
  network       = google_compute_network.main.id
}

resource "google_service_networking_connection" "private_vpc" {
  network                 = google_compute_network.main.id
  service                 = "servicenetworking.googleapis.com" # Googleのサービスネットワーク
  reserved_peering_ranges = [google_compute_global_address.private_ip.name]
}
