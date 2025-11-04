output "gke_project_enabled_apis" {
  description = "List of enabled APIs in the GKE project"
  value       = [for api in google_project_service.gke_project_apis : api.service]
}

output "vpc_host_project_enabled_apis" {
  description = "List of enabled APIs in the VPC host project"
  value       = [for api in google_project_service.vpc_host_project_apis : api.service]
}
