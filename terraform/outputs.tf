output "gke_cluster_name" {
  description = "Name of the GKE Cluster"
  value       = google_container_cluster.primary.name
}

output "artifact_registry_repo" {
  description = "Artifact Registry Docker URL"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.guestbook_repo.repository_id}"
}

output "cloud_sql_public_ip" {
  description = "Public IP Address of Cloud SQL Instance"
  value       = google_sql_database_instance.postgres_instance.public_ip_address
}


