terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Provider authenticated via credentials file
provider "google" {
  credentials = file(var.credentials_file)
  project     = var.project_id
  region      = var.region
  zone        = var.zone
}

# Fetch Service Account Key dynamically from GCP Secret Manager
data "google_secret_manager_secret_version" "sa_key" {
  secret  = "gcp-terraform-key"
  version = "latest"
}
