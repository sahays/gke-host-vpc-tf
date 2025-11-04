output "node_service_account_email" {
  description = "The email of the service account used by nodes"
  value       = var.create_service_account ? google_service_account.gke_node_sa[0].email : ""
}

output "node_service_account_name" {
  description = "The name of the service account used by nodes"
  value       = var.create_service_account ? google_service_account.gke_node_sa[0].name : ""
}

output "gke_project_number" {
  description = "The project number of the GKE project"
  value       = data.google_project.gke_project.number
}
