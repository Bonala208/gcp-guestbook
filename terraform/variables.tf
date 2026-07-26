variable "project_id" {
  description = "The GCP Project ID"
  type        = string
  default     = "guestbook-503604"
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "asia-southeast1"
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "asia-southeast1-b"
}

variable "credentials_file" {
  description = "Path to GCP Service Account Key JSON file"
  type        = string
  default     = "~/gcp-key.json"
}

variable "db_password" {
  description = "Root password for Cloud SQL PostgreSQL instance"
  type        = string
  default     = "YOUR_SECURE_PASSWORD"
  sensitive   = true
}
