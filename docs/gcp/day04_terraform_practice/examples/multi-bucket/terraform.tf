terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  # Remote State Backend を使うときは以下のコメントを外す
  # backend "gcs" {
  #   bucket = "YOUR_PROJECT_ID-tfstate"
  #   prefix = "day04/multi-bucket"
  # }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
