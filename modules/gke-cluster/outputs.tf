output "cluster_id" {
  description = "The ID of the cluster"
  value       = google_container_cluster.primary.id
}

output "cluster_name" {
  description = "The name of the cluster"
  value       = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  description = "The IP address of the cluster master"
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "The public certificate authority of the cluster"
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "cluster_location" {
  description = "The location of the cluster"
  value       = google_container_cluster.primary.location
}

output "cluster_self_link" {
  description = "The self link of the cluster"
  value       = google_container_cluster.primary.self_link
}

output "master_version" {
  description = "The current version of the master in the cluster"
  value       = google_container_cluster.primary.master_version
}

output "workload_identity_pool" {
  description = "The workload identity pool for the cluster"
  value       = var.enable_workload_identity ? "${var.gke_project_id}.svc.id.goog" : null
}
