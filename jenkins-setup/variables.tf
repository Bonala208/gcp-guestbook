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

variable "machine_type" {
  description = "GCP Compute Engine Machine Type"
  type        = string
  default     = "e2-standard-4" # 4 vCPUs, 16 GB RAM for Jenkins & SonarQube
}

variable "credentials_file" {
  description = "Path to GCP Service Account Key JSON file"
  type        = string
  default     = "~/gcp-key.json"
}

variable "agent_machine_type" {
  description = "GCP Compute Engine Machine Type for Jenkins Worker Agent VM"
  type        = string
  default     = "e2-standard-4" # 4 vCPUs, 16 GB RAM for build workloads
}
