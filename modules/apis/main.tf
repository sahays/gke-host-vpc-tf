# Enable APIs in GKE project
resource "google_project_service" "gke_project_apis" {
  for_each = toset([
    "container.googleapis.com",           # Google Kubernetes Engine API
    "compute.googleapis.com",             # Compute Engine API
    "monitoring.googleapis.com",          # Cloud Monitoring API
    "logging.googleapis.com",             # Cloud Logging API
    "cloudresourcemanager.googleapis.com", # Cloud Resource Manager API
    "servicenetworking.googleapis.com",   # Service Networking API
    "iam.googleapis.com",                 # Identity and Access Management API
    "iamcredentials.googleapis.com",      # IAM Service Account Credentials API
    "cloudtrace.googleapis.com",          # Cloud Trace API
    "stackdriver.googleapis.com",         # Stackdriver API
  ])

  project = var.gke_project_id
  service = each.value

  disable_on_destroy = false
}

# Enable APIs in VPC host project
resource "google_project_service" "vpc_host_project_apis" {
  for_each = toset([
    "compute.googleapis.com",             # Compute Engine API
    "container.googleapis.com",           # Required for shared VPC with GKE
    "servicenetworking.googleapis.com",   # Service Networking API
  ])

  project = var.vpc_host_project_id
  service = each.value

  disable_on_destroy = false
}
