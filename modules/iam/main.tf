locals {
  service_account_name = var.service_account_name != "" ? var.service_account_name : "${var.cluster_name}-node-sa"
}

# Create custom service account for GKE nodes
resource "google_service_account" "gke_node_sa" {
  count = var.create_service_account ? 1 : 0

  project      = var.gke_project_id
  account_id   = local.service_account_name
  display_name = "GKE Node Service Account for ${var.cluster_name}"
  description  = "Service account used by GKE nodes in cluster ${var.cluster_name}"
}

# Grant required roles to the GKE node service account in GKE project
resource "google_project_iam_member" "gke_node_sa_roles" {
  for_each = var.create_service_account ? toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer",
  ]) : toset([])

  project = var.gke_project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_node_sa[0].email}"
}

# Grant artifact registry reader role (if using Artifact Registry)
resource "google_project_iam_member" "gke_node_artifact_registry" {
  count = var.create_service_account ? 1 : 0

  project = var.gke_project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.gke_node_sa[0].email}"
}

# Grant storage object viewer role (if pulling images from GCS)
resource "google_project_iam_member" "gke_node_storage_viewer" {
  count = var.create_service_account ? 1 : 0

  project = var.gke_project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.gke_node_sa[0].email}"
}

# Grant the GKE service agent access to the host project
# This is required for shared VPC
data "google_project" "gke_project" {
  project_id = var.gke_project_id
}

# Grant GKE service agent the necessary roles in the host project
resource "google_project_iam_member" "gke_host_service_agent" {
  project = var.vpc_host_project_id
  role    = "roles/compute.networkUser"
  member  = "serviceAccount:service-${data.google_project.gke_project.number}@container-engine-robot.iam.gserviceaccount.com"
}

# Grant GKE service agent security admin role in host project for firewall rules
resource "google_project_iam_member" "gke_host_security_agent" {
  project = var.vpc_host_project_id
  role    = "roles/compute.securityAdmin"
  member  = "serviceAccount:service-${data.google_project.gke_project.number}@container-engine-robot.iam.gserviceaccount.com"
}

# Grant GKE service agent the host service agent user role for shared VPC
resource "google_project_iam_member" "gke_host_service_agent_user" {
  project = var.vpc_host_project_id
  role    = "roles/container.hostServiceAgentUser"
  member  = "serviceAccount:service-${data.google_project.gke_project.number}@container-engine-robot.iam.gserviceaccount.com"
}

# Grant the Google APIs service agent access to the host project
resource "google_project_iam_member" "google_apis_service_agent" {
  project = var.vpc_host_project_id
  role    = "roles/compute.networkUser"
  member  = "serviceAccount:${data.google_project.gke_project.number}@cloudservices.gserviceaccount.com"
}

# If the node service account is in the GKE project, grant it network user role in host project
resource "google_project_iam_member" "node_sa_network_user" {
  count = var.create_service_account ? 1 : 0

  project = var.vpc_host_project_id
  role    = "roles/compute.networkUser"
  member  = "serviceAccount:${google_service_account.gke_node_sa[0].email}"
}

# Workload Identity binding is configured per-application after cluster deployment
# See README.md and QUICKSTART.md for instructions on how to bind Kubernetes
# service accounts to Google Cloud service accounts using Workload Identity
