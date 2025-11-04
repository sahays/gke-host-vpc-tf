# GKE Terraform - Modular Deployment

Production-ready GKE cluster with support for both single-project and shared VPC deployments.

## Features

- ✅ **Regional GKE cluster** (multi-zone HA)
- ✅ **Private nodes** (no public IPs)
- ✅ **Custom E2 instances** (16 vCPU, 64GB RAM)
- ✅ **Cloud NAT** for internet access
- ✅ **Workload Identity** enabled
- ✅ **Monitoring & Logging** integrated
- ✅ **Flexible deployment** (single project or shared VPC)

## Quick Start

### 1. Choose Your Deployment Mode

| Mode | Use Case | Projects | Setup Time |
|------|----------|----------|------------|
| **Single Project** | Dev/Test | 1 | ~5 min |
| **Shared VPC** | Production | 2 | ~15 min |

### 2. Deploy

**Option A: Single Project (Simpler)**
```bash
# 1. Configure
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars
# Set both gke_project_id and vpc_host_project_id to SAME value

# 2. Deploy
make init
make apply

# 3. Connect
make connect
```

**Option B: Shared VPC (Production)**
```bash
# 1. Configure
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars
# Set gke_project_id and vpc_host_project_id to DIFFERENT values

# 2. Setup Shared VPC
make host-vpc-setup

# 3. Deploy
make init
make apply

# 4. Connect
make connect
```

## Configuration

### Required Variables

Edit `terraform.tfvars`:

```hcl
# Projects (same for single project, different for shared VPC)
gke_project_id      = "your-gke-project"
vpc_host_project_id = "your-vpc-project"

# Network
region                        = "us-central1"
network_name                  = "your-vpc"
subnet_name                   = "your-subnet"
pods_secondary_range_name     = "pods-range"
services_secondary_range_name = "services-range"

# Cluster
cluster_name = "my-gke-cluster"
```

### Optional Customization

```hcl
# Node pool settings
node_machine_type  = "custom-16-65536"  # 16 vCPU, 64GB RAM
node_min_count     = 1                   # Min nodes per zone
node_max_count     = 10                  # Max nodes per zone
node_disk_size_gb  = 100

# Cluster features
enable_workload_identity = true
enable_monitoring        = true
enable_logging           = true
enable_cloud_nat         = true
```

## Prerequisites

**Required:**
- Terraform >= 1.5.0
- gcloud CLI authenticated
- VPC network with primary subnet and two secondary ranges (pods, services)

**Permissions (Single Project):**
- `roles/container.admin`
- `roles/compute.networkAdmin`
- `roles/iam.serviceAccountAdmin`

**Permissions (Shared VPC - Additional):**
- `roles/compute.xpnAdmin` (org-level, to enable Shared VPC)
- If you lack org permissions, ask admin to run: `./scripts/enable-shared-vpc-admin.sh`

## Module Structure

```
.
├── main.tf                  # Root orchestration
├── variables.tf             # Input variables
├── outputs.tf               # Outputs
├── terraform.tfvars.example # Example config
├── Makefile                 # Helper commands
└── modules/
    ├── apis/                # API enablement
    ├── iam/                 # Service accounts & IAM
    ├── networking/          # Cloud NAT & firewall
    ├── gke-cluster/         # GKE cluster
    └── node-pool/           # Node pool config
```

## Common Commands

```bash
# Help
make help

# Setup Shared VPC (shared VPC mode only)
make host-vpc-setup

# Initialize Terraform
make init

# Plan changes
make plan

# Apply changes
make apply

# Connect to cluster
make connect

# Format Terraform files
make fmt

# Destroy everything
make destroy
```

## Post-Deployment

### Deploy a Test App

```bash
kubectl create deployment nginx --image=nginx:latest
kubectl expose deployment nginx --port=80 --type=LoadBalancer
kubectl get service nginx
```

### Setup Workload Identity

For apps that need to access Google Cloud services:

```bash
# 1. Create Kubernetes service account
kubectl create serviceaccount my-app-ksa -n default

# 2. Create Google service account
gcloud iam service-accounts create my-app-gsa \
    --project=your-gke-project-id

# 3. Grant GCP permissions
gcloud projects add-iam-policy-binding your-gke-project-id \
    --member="serviceAccount:my-app-gsa@your-gke-project-id.iam.gserviceaccount.com" \
    --role="roles/storage.objectViewer"

# 4. Bind service accounts
gcloud iam service-accounts add-iam-policy-binding \
    my-app-gsa@your-gke-project-id.iam.gserviceaccount.com \
    --role roles/iam.workloadIdentityUser \
    --member "serviceAccount:your-gke-project-id.svc.id.goog[default/my-app-ksa]"

# 5. Annotate Kubernetes service account
kubectl annotate serviceaccount my-app-ksa \
    iam.gke.io/gcp-service-account=my-app-gsa@your-gke-project-id.iam.gserviceaccount.com
```

## Deployment Modes Explained

### Single Project Mode
- **What**: VPC and GKE in same project
- **Best for**: Development, testing, simple deployments
- **Pros**: Faster setup, no org permissions needed
- **Cons**: No network isolation

### Shared VPC Mode
- **What**: VPC in host project, GKE in service project
- **Best for**: Production, multi-team environments
- **Pros**: Better security, centralized network management
- **Cons**: Requires org-level permissions, more complex setup

### Switching Modes

Change `vpc_host_project_id` in `terraform.tfvars`:
- **Single → Shared VPC**: Set to different project, run `make host-vpc-setup`
- **Shared VPC → Single**: Set to same as `gke_project_id`

**Note**: Requires resource recreation. Plan for downtime.

## Troubleshooting

### "Shared VPC not configured" error
```bash
# For shared VPC mode, run:
make host-vpc-setup
```

### "Permission denied" on Shared VPC setup
```bash
# Ask your org admin to run:
./scripts/enable-shared-vpc-admin.sh

# Or grant yourself org-level permissions:
gcloud organizations add-iam-policy-binding ORG_ID \
    --member='user:YOUR_EMAIL' \
    --role='roles/compute.xpnAdmin'
```

### "Shielded VM" constraint error
Already fixed in the configuration. If you see this error, ensure you're using the latest version.

### Check Shared VPC status
```bash
gcloud compute shared-vpc get-host-project YOUR_GKE_PROJECT
```

## Outputs

After deployment, get important values:

```bash
# All outputs
terraform output

# Specific output
terraform output cluster_name
terraform output cluster_endpoint

# Connection command
terraform output kubectl_connection_command
```

## Maintenance

### Scale nodes
Edit `terraform.tfvars`:
```hcl
node_min_count = 2
node_max_count = 20
```
Then: `terraform apply`

### Upgrade Kubernetes
```hcl
kubernetes_version = "1.29.5-gke.1000"
```
Then: `terraform apply`

## Security Features

- ✅ **Private nodes** (no public IPs)
- ✅ **Shielded nodes** with Secure Boot
- ✅ **Workload Identity** (no service account keys)
- ✅ **Master authorized networks** (configurable)
- ✅ **Cloud NAT** (controlled internet access)
- ✅ **Node auto-upgrade** enabled
- ✅ **Node auto-repair** enabled

## Cost Optimization

- Use cluster autoscaling (enabled by default)
- Consider preemptible nodes for non-critical workloads
- Monitor with GKE usage metering
- Right-size node machine types based on workload

## Resources

- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Shared VPC Overview](https://cloud.google.com/vpc/docs/shared-vpc)
- [Workload Identity Guide](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)
- [Scripts Documentation](./scripts/README.md)

## Contributing

Found an issue? Have a suggestion? Please open an issue or submit a pull request.

## License

This module is provided as-is for educational and production use.
