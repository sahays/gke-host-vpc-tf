variable "gke_project_id" {
  description = "The project ID where the GKE cluster will be created"
  type        = string
}

variable "vpc_host_project_id" {
  description = "The project ID where the shared VPC is hosted"
  type        = string
}

variable "create_service_account" {
  description = "Create a custom service account for GKE nodes"
  type        = bool
  default     = true
}

variable "service_account_name" {
  description = "Name of the service account for GKE nodes"
  type        = string
  default     = ""
}

variable "cluster_name" {
  description = "The name of the GKE cluster"
  type        = string
}

variable "enable_workload_identity" {
  description = "Enable Workload Identity for the cluster"
  type        = bool
  default     = true
}
