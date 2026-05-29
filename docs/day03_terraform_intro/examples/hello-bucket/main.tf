resource "google_storage_bucket" "hello" {
  name     = "${var.project_id}-hello-tf" # バケット名（グローバルで一意にする必要がある）
  location = var.region                   # バケットのロケーション（リージョン or マルチリージョン）

  force_destroy = true # terraform destroy時にオブジェクトが残っていても削除可能にする

  labels = {
    env     = "training"  # リソースのタグ付け（課金管理やフィルタリングに使う）
    managed = "terraform" # Terraform管理であることを明示
  }
}
