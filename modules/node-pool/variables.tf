variable "gke_project_id" {
  description = "The project ID where the GKE cluster is located"
  type        = string
}

variable "region" {
  description = "The region where the GKE cluster is located"
  type        = string
}

variable "cluster_name" {
  description = "The name of the GKE cluster"
  type        = string
}

variable "node_pool_name" {
  description = "The name of the node pool"
  type        = string
}

variable "node_machine_type" {
  description = "The machine type for nodes"
  type        = string
  default     = "custom-16-65536"
}

variable "node_disk_size_gb" {
  description = "Size of the disk attached to each node"
  type        = number
  default     = 100
}

variable "node_disk_type" {
  description = "Type of the disk attached to each node"
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

variable "service_account" {
  description = "The service account to use for the nodes"
  type        = string
}

variable "enable_workload_identity" {
  description = "Enable Workload Identity for the node pool"
  type        = bool
  default     = true
}
