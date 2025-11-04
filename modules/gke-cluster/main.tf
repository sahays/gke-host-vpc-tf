# Create GKE cluster
resource "google_container_cluster" "primary" {
  provider = google-beta

  project  = var.gke_project_id
  name     = var.cluster_name
  location = var.region

  # Specify zones if provided, otherwise use all zones in the region
  node_locations = length(var.zones) > 0 ? var.zones : null

  description = var.cluster_description

  # Minimum version for initial cluster creation
  min_master_version = var.kubernetes_version

  # Release channel configuration
  release_channel {
    channel = var.release_channel
  }

  # Network configuration using shared VPC
  network    = "projects/${var.vpc_host_project_id}/global/networks/${var.network_name}"
  subnetwork = "projects/${var.vpc_host_project_id}/regions/${var.region}/subnetworks/${var.subnet_name}"

  # IP allocation policy for pods and services
  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_secondary_range_name
    services_secondary_range_name = var.services_secondary_range_name
  }

  # Private cluster configuration
  dynamic "private_cluster_config" {
    for_each = var.enable_private_cluster ? [1] : []
    content {
      enable_private_nodes    = var.enable_private_nodes
      enable_private_endpoint = var.enable_private_endpoint
      master_ipv4_cidr_block  = var.master_ipv4_cidr_block

      master_global_access_config {
        enabled = true
      }
    }
  }

  # Master authorized networks configuration
  dynamic "master_authorized_networks_config" {
    for_each = length(var.master_authorized_networks) > 0 ? [1] : []
    content {
      dynamic "cidr_blocks" {
        for_each = var.master_authorized_networks
        content {
          cidr_block   = cidr_blocks.value.cidr_block
          display_name = cidr_blocks.value.display_name
        }
      }
    }
  }

  # Workload Identity configuration
  dynamic "workload_identity_config" {
    for_each = var.enable_workload_identity ? [1] : []
    content {
      workload_pool = "${var.gke_project_id}.svc.id.goog"
    }
  }

  # Network policy configuration
  network_policy {
    enabled  = var.enable_network_policy
    provider = var.enable_network_policy ? "PROVIDER_UNSPECIFIED" : null
  }

  # Addons configuration
  addons_config {
    http_load_balancing {
      disabled = false
    }

    horizontal_pod_autoscaling {
      disabled = false
    }

    network_policy_config {
      disabled = !var.enable_network_policy
    }

    gce_persistent_disk_csi_driver_config {
      enabled = true
    }

    gcp_filestore_csi_driver_config {
      enabled = true
    }

    gcs_fuse_csi_driver_config {
      enabled = true
    }
  }

  # Binary authorization configuration
  dynamic "binary_authorization" {
    for_each = var.enable_binary_authorization ? [1] : []
    content {
      evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
    }
  }

  # Monitoring and logging configuration
  monitoring_config {
    enable_components = var.enable_monitoring ? ["SYSTEM_COMPONENTS"] : []

    managed_prometheus {
      enabled = var.enable_monitoring
    }
  }

  logging_config {
    enable_components = var.enable_logging ? ["SYSTEM_COMPONENTS"] : []
  }

  # Maintenance window configuration
  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
  }

  # Cluster resource labels
  resource_labels = var.cluster_labels

  # Enable shielded nodes
  enable_shielded_nodes = true

  # Enable dataplane V2 (for better networking performance)
  datapath_provider = "ADVANCED_DATAPATH"

  # Remove default node pool and manage node pools separately
  remove_default_node_pool = true
  initial_node_count       = 1

  # Deletion protection
  deletion_protection = false

  # Cluster autoscaling (node auto-provisioning)
  cluster_autoscaling {
    enabled = false
  }

  # Lifecycle rules to prevent accidental changes
  lifecycle {
    ignore_changes = [
      node_pool,
      initial_node_count,
    ]
  }
}
