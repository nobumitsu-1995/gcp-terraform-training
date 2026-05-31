resource "google_storage_bucket" "this" {
  name     = var.bucket_name # 呼び出し側から渡されるバケット名
  location = var.location    # 呼び出し側から渡されるロケーション

  versioning {
    enabled = var.versioning_enabled # オブジェクトのバージョニング（上書き時に旧版を保持）
  }

  lifecycle_rule {
    condition {
      age = var.lifecycle_age_days # 指定日数を超えたオブジェクトを自動削除
    }
    action {
      type = "Delete" # 条件に合致したら削除する
    }
  }

  uniform_bucket_level_access = true # オブジェクト単位でなくバケット単位でアクセス制御
  force_destroy               = true # destroy時にオブジェクトが残っていても削除可能
}
