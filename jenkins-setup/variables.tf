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
  default     = "asia-southeast1-b"
}

variable "machine_type" {
  description = "GCE Machine Type for Jenkins Server"
  type        = string
  default     = "e2-medium"
}

variable "credentials_file" {
  description = "Path to GCP Service Account Key JSON file"
  type        = string
  default     = "~/gcp-key.json"
}
