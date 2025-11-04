# Get cluster information
data "google_container_cluster" "cluster" {
  project  = var.gke_project_id
  name     = var.cluster_name
  location = var.region
}

# Create node pool with custom E2 machine type
resource "google_container_node_pool" "primary" {
  provider = google-beta

  project  = var.gke_project_id
  name     = var.node_pool_name
  location = var.region
  cluster  = data.google_container_cluster.cluster.name

  # Initial node count per zone
  initial_node_count = var.node_initial_count

  # Autoscaling configuration
  autoscaling {
    min_node_count = var.node_min_count
    max_node_count = var.node_max_count
  }

  # Node management configuration
  management {
    auto_repair  = true
    auto_upgrade = true
  }

  # Upgrade settings
  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
    strategy        = "SURGE"
  }

  # Node configuration
  node_config {
    # Custom E2 machine type: 16 vCPU, 64GB RAM
    # Format: custom-{CPUS}-{MEMORY_MB}
    # 64GB = 65536 MB
    machine_type = var.node_machine_type

    # Disk configuration
    disk_size_gb = var.node_disk_size_gb
    disk_type    = var.node_disk_type

    # Image type
    image_type = var.node_image_type

    # Service account
    service_account = var.service_account

    # OAuth scopes for the node
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    # Labels
    labels = merge(
      var.node_labels,
      {
        "cluster"   = var.cluster_name
        "node-pool" = var.node_pool_name
      }
    )

    # Tags
    tags = concat(
      var.node_tags,
      ["${var.cluster_name}-gke-node"]
    )

    # Metadata
    metadata = {
      disable-legacy-endpoints = "true"
    }

    # Workload Identity configuration
    dynamic "workload_metadata_config" {
      for_each = var.enable_workload_identity ? [1] : []
      content {
        mode = "GKE_METADATA"
      }
    }

    # Shielded instance configuration
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    # Preemptible nodes (set to false for production)
    preemptible = false

    # Node taints (optional - uncomment if needed)
    # taint {
    #   key    = "app"
    #   value  = "nodejs"
    #   effect = "NO_SCHEDULE"
    # }
  }

  # Lifecycle policy
  lifecycle {
    ignore_changes = [
      initial_node_count,
    ]
  }
}
