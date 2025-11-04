output "cloud_router_name" {
  description = "The name of the Cloud Router"
  value       = var.enable_cloud_nat ? google_compute_router.router[0].name : ""
}

output "cloud_nat_name" {
  description = "The name of the Cloud NAT"
  value       = var.enable_cloud_nat ? google_compute_router_nat.nat[0].name : ""
}

output "network_id" {
  description = "The ID of the VPC network"
  value       = data.google_compute_network.vpc.id
}

output "subnet_id" {
  description = "The ID of the subnet"
  value       = data.google_compute_subnetwork.subnet.id
}
