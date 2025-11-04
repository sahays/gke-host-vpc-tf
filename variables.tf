# Project Configuration
variable "gke_project_id" {
  description = "The project ID where the GKE cluster will be created"
  type        = string
}

variable "vpc_host_project_id" {
  description = "The project ID where the shared VPC is hosted"
  type        = string
}

# Region and Zones
variable "region" {
  description = "The region for the GKE cluster"
  type        = string
}

variable "zones" {
  description = "List of zones for the GKE cluster. If not specified, all zones in the region will be used"
  type        = list(string)
  default     = []
}

# Network Configuration
variable "network_name" {
  description = "The name of the VPC network in the host project"
  type        = string
}

variable "subnet_name" {
  description = "The name of the primary subnet for nodes"
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

# Cluster Configuration
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
  description = "The Kubernetes version for the cluster. If not specified, latest version from the selected release channel will be used"
  type        = string
  default     = null
}

variable "release_channel" {
  description = "The release channel for GKE cluster (RAPID, REGULAR, STABLE)"
  type        = string
  default     = "REGULAR"
}

# Private Cluster Configuration
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
  description = "The IP range in CIDR notation to use for the hosted master network"
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

# Node Pool Configuration
variable "node_pool_name" {
  description = "The name of the node pool"
  type        = string
  default     = "primary-node-pool"
}

variable "node_machine_type" {
  description = "The machine type for nodes (use custom-{CPUS}-{MEMORY} format for custom types)"
  type        = string
  default     = "custom-16-65536"  # 16 vCPU, 64GB RAM (65536 MB)
}

variable "node_disk_size_gb" {
  description = "Size of the disk attached to each node, specified in GB"
  type        = number
  default     = 100
}

variable "node_disk_type" {
  description = "Type of the disk attached to each node (pd-standard, pd-balanced, pd-ssd)"
  type        = string
  default     = "pd-balanced"
}

variable "node_image_type" {
  description = "The image type to use for the node pool"
  type        = string
  default     = "COS_CONTAINERD"
}

variable "node_min_count" {
  description = "Minimum number of nodes per zone"
  type        = number
  default     = 1
}

variable "node_max_count" {
  description = "Maximum number of nodes per zone"
  type        = number
  default     = 10
}

variable "node_initial_count" {
  description = "Initial number of nodes per zone"
  type        = number
  default     = 1
}

# Feature Flags
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

variable "enable_cloud_nat" {
  description = "Enable Cloud NAT for the VPC"
  type        = bool
  default     = true
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

# Service Account Configuration
variable "create_service_account" {
  description = "Create a custom service account for GKE nodes"
  type        = bool
  default     = true
}

variable "service_account_name" {
  description = "Name of the service account for GKE nodes. If not specified, a name will be generated"
  type        = string
  default     = ""
}

# Labels and Tags
variable "cluster_labels" {
  description = "Labels to apply to the cluster"
  type        = map(string)
  default     = {}
}

variable "node_labels" {
  description = "Labels to apply to the nodes"
  type        = map(string)
  default     = {}
}

variable "node_tags" {
  description = "Network tags to apply to the nodes"
  type        = list(string)
  default     = ["gke-node"]
}

# Maintenance Window
variable "maintenance_start_time" {
  description = "Start time for the maintenance window in RFC3339 format"
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
