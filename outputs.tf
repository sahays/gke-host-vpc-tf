# Cluster Outputs
output "cluster_name" {
  description = "The name of the GKE cluster"
  value       = module.gke_cluster.cluster_name
}

output "cluster_endpoint" {
  description = "The IP address of the cluster master"
  value       = module.gke_cluster.cluster_endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "The public certificate authority of the cluster"
  value       = module.gke_cluster.cluster_ca_certificate
  sensitive   = true
}

output "cluster_location" {
  description = "The location of the cluster"
  value       = module.gke_cluster.cluster_location
}

# Service Account Outputs
output "node_service_account_email" {
  description = "The email of the service account used by nodes"
  value       = module.iam.node_service_account_email
}

# Network Outputs
output "cloud_nat_name" {
  description = "The name of the Cloud NAT"
  value       = module.networking.cloud_nat_name
}

output "cloud_router_name" {
  description = "The name of the Cloud Router"
  value       = module.networking.cloud_router_name
}

# Node Pool Outputs
output "node_pool_name" {
  description = "The name of the node pool"
  value       = module.node_pool.node_pool_name
}

# Connection Command
output "kubectl_connection_command" {
  description = "Command to configure kubectl"
  value       = "gcloud container clusters get-credentials ${module.gke_cluster.cluster_name} --region ${var.region} --project ${var.gke_project_id}"
}
