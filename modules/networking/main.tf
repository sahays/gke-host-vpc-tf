# Data source to get the network information
data "google_compute_network" "vpc" {
  project = var.vpc_host_project_id
  name    = var.network_name
}

# Data source to get the subnet information
data "google_compute_subnetwork" "subnet" {
  project = var.vpc_host_project_id
  name    = var.subnet_name
  region  = var.region
}

# Create Cloud Router for Cloud NAT (created in host project)
resource "google_compute_router" "router" {
  count = var.enable_cloud_nat ? 1 : 0

  project = var.vpc_host_project_id
  name    = "${var.cluster_name}-router"
  region  = var.region
  network = data.google_compute_network.vpc.id

  description = "Cloud Router for GKE cluster ${var.cluster_name}"
}

# Create Cloud NAT for private GKE nodes to access internet
resource "google_compute_router_nat" "nat" {
  count = var.enable_cloud_nat ? 1 : 0

  project = var.vpc_host_project_id
  name    = "${var.cluster_name}-nat"
  router  = google_compute_router.router[0].name
  region  = var.region

  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Firewall rule to allow internal communication within the VPC (if needed)
resource "google_compute_firewall" "allow_internal" {
  project = var.vpc_host_project_id
  name    = "${var.cluster_name}-allow-internal"
  network = data.google_compute_network.vpc.name

  description = "Allow internal communication for GKE cluster ${var.cluster_name}"

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [
    data.google_compute_subnetwork.subnet.ip_cidr_range,
  ]

  target_tags = ["gke-node", "${var.cluster_name}-gke-node"]
}

# Firewall rule to allow health checks from Google Cloud Load Balancers
resource "google_compute_firewall" "allow_health_checks" {
  project = var.vpc_host_project_id
  name    = "${var.cluster_name}-allow-health-checks"
  network = data.google_compute_network.vpc.name

  description = "Allow health checks from Google Cloud Load Balancers"

  allow {
    protocol = "tcp"
  }

  source_ranges = [
    "35.191.0.0/16",  # Google Cloud Load Balancer health check ranges
    "130.211.0.0/22",
  ]

  target_tags = ["gke-node", "${var.cluster_name}-gke-node"]
}
