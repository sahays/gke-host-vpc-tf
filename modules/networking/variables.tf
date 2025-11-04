variable "gke_project_id" {
  description = "The project ID where the GKE cluster will be created"
  type        = string
}

variable "vpc_host_project_id" {
  description = "The project ID where the shared VPC is hosted"
  type        = string
}

variable "region" {
  description = "The region for the Cloud Router and Cloud NAT"
  type        = string
}

variable "network_name" {
  description = "The name of the VPC network"
  type        = string
}

variable "subnet_name" {
  description = "The name of the subnet"
  type        = string
}

variable "enable_cloud_nat" {
  description = "Enable Cloud NAT for the VPC"
  type        = bool
  default     = true
}

variable "cluster_name" {
  description = "The name of the GKE cluster (used for naming resources)"
  type        = string
}
