output "node_pool_id" {
  description = "The ID of the node pool"
  value       = google_container_node_pool.primary.id
}

output "node_pool_name" {
  description = "The name of the node pool"
  value       = google_container_node_pool.primary.name
}

output "node_pool_version" {
  description = "The Kubernetes version running on the node pool"
  value       = google_container_node_pool.primary.version
}

output "node_pool_instance_group_urls" {
  description = "The instance group URLs of the node pool"
  value       = google_container_node_pool.primary.managed_instance_group_urls
}
