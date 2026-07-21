# 1. Enable Required GCP APIs
resource "google_project_service" "container_api" {
  service            = "container.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "sqladmin_api" {
  service            = "sqladmin.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "artifactregistry_api" {
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

# 2. Create GCP Artifact Registry Repository
resource "google_artifact_registry_repository" "guestbook_repo" {
  depends_on    = [google_project_service.artifactregistry_api]
  location      = var.region
  repository_id = "guestbook-repo"
  description   = "Docker repository for Guestbook container images"
  format        = "DOCKER"
}

# 3. Create GCP Cloud SQL PostgreSQL Instance
resource "google_sql_database_instance" "postgres_instance" {
  depends_on       = [google_project_service.sqladmin_api]
  name             = "guestbook-db-instance"
  database_version = "POSTGRES_15"
  region           = var.region
  deletion_protection = false

  settings {
    tier = "db-f1-micro"

    ip_configuration {
      ipv4_enabled = true

      # Authorize all IPs temporarily for GKE connection testing
      authorized_networks {
        name  = "allow-all"
        value = "0.0.0.0/0"
      }
    }
  }
}

# Set PostgreSQL root user password
resource "google_sql_user" "root_user" {
  name     = "postgres"
  instance = google_sql_database_instance.postgres_instance.name
  password = var.db_password
}

# 4. Create GKE Standard Zonal Cluster (2 nodes)
resource "google_container_cluster" "primary" {
  depends_on       = [google_project_service.container_api]
  name             = "guestbook-cluster"
  location         = var.zone
  initial_node_count = 2
  min_master_version = "1.33.12-gke.1059000"

  node_config {
    machine_type = "e2-medium"
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}
