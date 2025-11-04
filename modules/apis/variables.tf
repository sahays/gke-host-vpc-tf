variable "gke_project_id" {
  description = "The project ID where the GKE cluster will be created"
  type        = string
}

variable "vpc_host_project_id" {
  description = "The project ID where the shared VPC is hosted"
  type        = string
}
