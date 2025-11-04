variable "gke_project_id" {
  description = "The project ID where the GKE cluster will be created"
  type        = string
}

variable "vpc_host_project_id" {
  description = "The project ID where the shared VPC is hosted"
  type        = string
}

variable "region" {
  description = "The region for the GKE cluster"
  type        = string
}

variable "zones" {
  description = "List of zones for the GKE cluster"
  type        = list(string)
  default     = []
}

variable "cluster_name" {
  description = "The name of the GKE cluster"
  type        = string
}

variable "cluster_description" {
  description = "Description of the GKE cluster"
  type        = string
  default     = "GKE cluster with shared VPC"
}

variable "kubernetes_version" {
  description = "The Kubernetes version for the cluster"
  type        = string
  default     = null
}

variable "release_channel" {
  description = "The release channel for GKE cluster"
  type        = string
  default     = "REGULAR"
}

variable "network_name" {
  description = "The name of the VPC network"
  type        = string
}

variable "subnet_name" {
  description = "The name of the subnet"
  type        = string
}

variable "pods_secondary_range_name" {
  description = "The name of the secondary IP range for pods"
  type        = string
}

variable "services_secondary_range_name" {
  description = "The name of the secondary IP range for services"
  type        = string
}

variable "enable_private_cluster" {
  description = "Enable private cluster configuration"
  type        = bool
  default     = true
}

variable "enable_private_nodes" {
  description = "Nodes have only private IP addresses"
  type        = bool
  default     = true
}

variable "enable_private_endpoint" {
  description = "Control plane is accessible only via private IP"
  type        = bool
  default     = false
}

variable "master_ipv4_cidr_block" {
  description = "The IP range in CIDR notation for the hosted master network"
  type        = string
  default     = "172.16.0.0/28"
}

variable "master_authorized_networks" {
  description = "List of master authorized networks"
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []
}

variable "enable_workload_identity" {
  description = "Enable Workload Identity for the cluster"
  type        = bool
  default     = true
}

variable "enable_network_policy" {
  description = "Enable network policy for the cluster"
  type        = bool
  default     = false
}

variable "enable_binary_authorization" {
  description = "Enable binary authorization for the cluster"
  type        = bool
  default     = false
}

variable "enable_monitoring" {
  description = "Enable Google Cloud Monitoring"
  type        = bool
  default     = true
}

variable "enable_logging" {
  description = "Enable Google Cloud Logging"
  type        = bool
  default     = true
}

variable "cluster_labels" {
  description = "Labels to apply to the cluster"
  type        = map(string)
  default     = {}
}

variable "maintenance_start_time" {
  description = "Start time for the maintenance window"
  type        = string
  default     = "2024-01-01T03:00:00Z"
}

variable "maintenance_duration" {
  description = "Duration of the maintenance window"
  type        = string
  default     = "4h"
}

variable "maintenance_recurrence" {
  description = "Recurrence schedule for maintenance window"
  type        = string
  default     = "FREQ=WEEKLY;BYDAY=SU"
}
