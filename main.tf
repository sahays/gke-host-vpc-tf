# Enable required APIs
module "apis" {
  source = "./modules/apis"

  gke_project_id      = var.gke_project_id
  vpc_host_project_id = var.vpc_host_project_id
}

# Create service accounts and IAM bindings
module "iam" {
  source = "./modules/iam"

  gke_project_id         = var.gke_project_id
  vpc_host_project_id    = var.vpc_host_project_id
  create_service_account = var.create_service_account
  service_account_name   = var.service_account_name
  cluster_name           = var.cluster_name
  enable_workload_identity = var.enable_workload_identity

  depends_on = [module.apis]
}

# Configure networking (Cloud NAT, firewall rules)
module "networking" {
  source = "./modules/networking"

  gke_project_id      = var.gke_project_id
  vpc_host_project_id = var.vpc_host_project_id
  region              = var.region
  network_name        = var.network_name
  subnet_name         = var.subnet_name
  enable_cloud_nat    = var.enable_cloud_nat
  cluster_name        = var.cluster_name

  depends_on = [module.apis]
}

# Create GKE cluster
module "gke_cluster" {
  source = "./modules/gke-cluster"

  gke_project_id                = var.gke_project_id
  vpc_host_project_id           = var.vpc_host_project_id
  region                        = var.region
  zones                         = var.zones
  cluster_name                  = var.cluster_name
  cluster_description           = var.cluster_description
  kubernetes_version            = var.kubernetes_version
  release_channel               = var.release_channel
  network_name                  = var.network_name
  subnet_name                   = var.subnet_name
  pods_secondary_range_name     = var.pods_secondary_range_name
  services_secondary_range_name = var.services_secondary_range_name
  enable_private_cluster        = var.enable_private_cluster
  enable_private_nodes          = var.enable_private_nodes
  enable_private_endpoint       = var.enable_private_endpoint
  master_ipv4_cidr_block        = var.master_ipv4_cidr_block
  master_authorized_networks    = var.master_authorized_networks
  enable_workload_identity      = var.enable_workload_identity
  enable_network_policy         = var.enable_network_policy
  enable_binary_authorization   = var.enable_binary_authorization
  enable_monitoring             = var.enable_monitoring
  enable_logging                = var.enable_logging
  cluster_labels                = var.cluster_labels
  maintenance_start_time        = var.maintenance_start_time
  maintenance_duration          = var.maintenance_duration
  maintenance_recurrence        = var.maintenance_recurrence

  depends_on = [module.apis, module.iam, module.networking]
}

# Create node pool
module "node_pool" {
  source = "./modules/node-pool"

  gke_project_id       = var.gke_project_id
  region               = var.region
  cluster_name         = var.cluster_name
  node_pool_name       = var.node_pool_name
  node_machine_type    = var.node_machine_type
  node_disk_size_gb    = var.node_disk_size_gb
  node_disk_type       = var.node_disk_type
  node_image_type      = var.node_image_type
  node_min_count       = var.node_min_count
  node_max_count       = var.node_max_count
  node_initial_count   = var.node_initial_count
  node_labels          = var.node_labels
  node_tags            = var.node_tags
  service_account      = module.iam.node_service_account_email
  enable_workload_identity = var.enable_workload_identity

  depends_on = [module.gke_cluster]
}
