variable "project_id" {
  description = "The GCP Project ID"
  type        = string
  default     = "pythonproject-502117"
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "asia-southeast1"
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "asia-southeast1-a"
}

variable "db_password" {
  description = "Root password for Cloud SQL PostgreSQL instance"
  type        = string
  default     = "YOUR_SECURE_PASSWORD"
  sensitive   = true
}
