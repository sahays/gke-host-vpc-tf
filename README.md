# GKE Cluster with Shared VPC - Terraform Module

This repository contains a modular Terraform configuration for deploying a production-ready Google Kubernetes Engine (GKE) cluster using a Shared VPC architecture.

## Architecture Overview

This setup creates:

- **GKE Regional Cluster**: Highly available cluster spread across multiple zones
- **Shared VPC**: Uses a VPC hosted in a separate networking project
- **Private Cluster**: Nodes without public IPs for enhanced security
- **Custom E2 Instances**: 16 vCPU, 64GB RAM nodes optimized for Node.js applications
- **Cloud NAT**: Enables private nodes to access the internet
- **Workload Identity**: Secure way for pods to access Google Cloud services
- **Monitoring & Logging**: Google Cloud Operations integration

```
┌─────────────────────────────────────────────────────────────────┐
│                     VPC Host Project                            │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Shared VPC Network                                      │   │
│  │  ┌────────────────┐  ┌──────────────────────────────┐   │   │
│  │  │ Primary Subnet │  │ Secondary Ranges             │   │   │
│  │  │ (Nodes)        │  │  - Pods IP Range             │   │   │
│  │  │                │  │  - Services IP Range         │   │   │
│  │  └────────────────┘  └──────────────────────────────┘   │   │
│  │                                                          │   │
│  │  ┌────────────────┐                                     │   │
│  │  │  Cloud NAT     │                                     │   │
│  │  │  Cloud Router  │                                     │   │
│  │  └────────────────┘                                     │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                     GKE Project                                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  GKE Cluster (Regional)                                  │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │   │
│  │  │  Zone A     │  │  Zone B     │  │  Zone C     │     │   │
│  │  │  - Node Pool│  │  - Node Pool│  │  - Node Pool│     │   │
│  │  │    E2 Custom│  │    E2 Custom│  │    E2 Custom│     │   │
│  │  │    16vCPU   │  │    16vCPU   │  │    16vCPU   │     │   │
│  │  │    64GB RAM │  │    64GB RAM │  │    64GB RAM │     │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘     │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## Module Structure

```
.
├── main.tf                      # Root module orchestration
├── variables.tf                 # Input variables
├── outputs.tf                   # Output values
├── versions.tf                  # Provider configuration
├── terraform.tfvars.example     # Example variable values
├── README.md                    # This file
└── modules/
    ├── apis/                    # API enablement
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── iam/                     # Service accounts and IAM
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── networking/              # Cloud NAT and firewall rules
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── gke-cluster/             # GKE cluster configuration
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── node-pool/               # Node pool with custom E2 instances
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## Prerequisites

Before you begin, ensure you have:

1. **Two GCP Projects**:
   - VPC Host Project (for shared VPC)
   - GKE Project (for the GKE cluster)

2. **Shared VPC Setup**:
   - **Option A (Automated):** Run `make setup` to configure Shared VPC
   - **Option B (Manual):** Pre-configure Shared VPC before running Terraform
   - Primary subnet with two secondary ranges (for pods and services) must exist

   **Note:** Enabling Shared VPC requires organization-level permissions. See [scripts/README.md](scripts/README.md) for details.

3. **Tools Installed**:
   - [Terraform](https://www.terraform.io/downloads) >= 1.5.0
   - [gcloud CLI](https://cloud.google.com/sdk/docs/install)
   - [kubectl](https://kubernetes.io/docs/tasks/tools/)

4. **GCP Permissions**:

   **For Shared VPC Setup:**
   - `roles/compute.xpnAdmin` (Shared VPC Admin) - **Organization level** (to enable Shared VPC)
   - `roles/compute.xpnAdmin` on VPC host project (to attach service projects)

   **For Terraform Deployment:**
   - `roles/compute.networkAdmin` (VPC host project)
   - `roles/container.admin` (GKE project)
   - `roles/iam.serviceAccountAdmin` (GKE project)
   - `roles/serviceusage.serviceUsageAdmin` (both projects)

   **Note:** If you don't have org-level permissions, ask your Organization Admin to run `scripts/enable-shared-vpc-admin.sh`

## Setup Instructions

### 1. Authenticate with Google Cloud

```bash
gcloud auth application-default login
```

### 2. Enable Shared VPC (if not already done)

In the VPC host project:

```bash
# Set VPC host project
export VPC_HOST_PROJECT_ID="your-vpc-host-project-id"

# Enable shared VPC
gcloud compute shared-vpc enable $VPC_HOST_PROJECT_ID
```

### 3. Attach GKE Project to Shared VPC

```bash
# Set GKE project
export GKE_PROJECT_ID="your-gke-project-id"

# Attach service project
gcloud compute shared-vpc associated-projects add $GKE_PROJECT_ID \
    --host-project $VPC_HOST_PROJECT_ID
```

### 4. Create VPC Network and Subnets (if not already done)

```bash
# Create VPC network
gcloud compute networks create shared-vpc-network \
    --project=$VPC_HOST_PROJECT_ID \
    --subnet-mode=custom

# Create subnet with secondary ranges
gcloud compute networks subnets create gke-subnet \
    --project=$VPC_HOST_PROJECT_ID \
    --network=shared-vpc-network \
    --region=us-central1 \
    --range=10.0.0.0/20 \
    --secondary-range pods-secondary-range=10.4.0.0/14 \
    --secondary-range services-secondary-range=10.8.0.0/20
```

### 5. Configure Terraform Variables

```bash
# Copy the example file
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
# Use your preferred editor (vim, nano, vscode, etc.)
vim terraform.tfvars
```

Fill in the required values:

```hcl
gke_project_id              = "your-gke-project-id"
vpc_host_project_id         = "your-vpc-host-project-id"
region                      = "us-central1"
network_name                = "shared-vpc-network"
subnet_name                 = "gke-subnet"
pods_secondary_range_name   = "pods-secondary-range"
services_secondary_range_name = "services-secondary-range"
cluster_name                = "my-gke-cluster"
```

### 6. Initialize Terraform

```bash
terraform init
```

### 7. Review the Execution Plan

```bash
terraform plan
```

Review the resources that will be created.

### 8. Apply the Configuration

```bash
terraform apply
```

Type `yes` when prompted to confirm.

**Note**: The deployment typically takes 10-15 minutes.

## Post-Deployment

### Connect to Your Cluster

```bash
# Get cluster credentials
gcloud container clusters get-credentials my-gke-cluster \
    --region us-central1 \
    --project your-gke-project-id

# Verify connection
kubectl get nodes
kubectl cluster-info
```

### Deploy a Sample Application

```bash
# Create a simple nginx deployment
kubectl create deployment nginx --image=nginx:latest

# Expose the deployment
kubectl expose deployment nginx --port=80 --type=LoadBalancer

# Get the external IP
kubectl get service nginx
```

### Configure Workload Identity (for applications)

To allow your pods to access Google Cloud services:

```bash
# Create a Kubernetes service account
kubectl create serviceaccount my-app-ksa -n default

# Create a Google service account
gcloud iam service-accounts create my-app-gsa \
    --project=your-gke-project-id

# Bind them together
gcloud iam service-accounts add-iam-policy-binding \
    my-app-gsa@your-gke-project-id.iam.gserviceaccount.com \
    --role roles/iam.workloadIdentityUser \
    --member "serviceAccount:your-gke-project-id.svc.id.goog[default/my-app-ksa]"

# Annotate the Kubernetes service account
kubectl annotate serviceaccount my-app-ksa \
    iam.gke.io/gcp-service-account=my-app-gsa@your-gke-project-id.iam.gserviceaccount.com
```

## Configuration Reference

### Key Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `gke_project_id` | GKE cluster project ID | Required |
| `vpc_host_project_id` | VPC host project ID | Required |
| `region` | GCP region | Required |
| `cluster_name` | GKE cluster name | Required |
| `node_machine_type` | Machine type for nodes | `custom-16-65536` |
| `node_min_count` | Min nodes per zone | `1` |
| `node_max_count` | Max nodes per zone | `10` |
| `enable_private_cluster` | Enable private cluster | `true` |
| `enable_workload_identity` | Enable Workload Identity | `true` |
| `enable_cloud_nat` | Enable Cloud NAT | `true` |

See `variables.tf` for the complete list.

### Machine Type Specifications

The default configuration uses custom E2 instances:
- **Machine Type**: `custom-16-65536`
- **vCPUs**: 16
- **Memory**: 64GB (65536 MB)
- **Disk**: 100GB balanced persistent disk

To change the machine type, modify `node_machine_type` in `terraform.tfvars`:

```hcl
# Custom machine type format: custom-{CPUS}-{MEMORY_MB}
node_machine_type = "custom-16-65536"  # 16 vCPU, 64GB RAM

# Or use predefined machine types:
# node_machine_type = "e2-standard-16"  # 16 vCPU, 64GB RAM
# node_machine_type = "n2-standard-16"  # 16 vCPU, 64GB RAM
```

## Outputs

After successful deployment, Terraform provides these outputs:

```hcl
cluster_name                  # Name of the GKE cluster
cluster_endpoint              # Cluster master endpoint (sensitive)
cluster_ca_certificate        # Cluster CA certificate (sensitive)
node_service_account_email    # Node service account email
kubectl_connection_command    # Command to connect to cluster
```

View outputs:

```bash
terraform output
terraform output -json  # JSON format
```

## Maintenance

### Updating the Cluster

```bash
# Modify terraform.tfvars or *.tf files
# Review changes
terraform plan

# Apply changes
terraform apply
```

### Scaling Nodes

Modify autoscaling parameters in `terraform.tfvars`:

```hcl
node_min_count = 2   # Increase minimum nodes
node_max_count = 20  # Increase maximum nodes
```

Apply changes:

```bash
terraform apply
```

### Upgrading Kubernetes Version

```bash
# Check available versions
gcloud container get-server-config \
    --region us-central1 \
    --project your-gke-project-id

# Update terraform.tfvars
kubernetes_version = "1.28.5-gke.1000"

# Apply
terraform apply
```

## Troubleshooting

### API Not Enabled Error

If you see API enablement errors:

```bash
# Manually enable required APIs
gcloud services enable container.googleapis.com \
    --project=your-gke-project-id
```

### Shared VPC Permission Issues

Ensure the GKE service account has proper permissions:

```bash
# Get the GKE project number
export PROJECT_NUMBER=$(gcloud projects describe $GKE_PROJECT_ID --format='value(projectNumber)')

# Grant permissions
gcloud projects add-iam-policy-binding $VPC_HOST_PROJECT_ID \
    --member=serviceAccount:service-${PROJECT_NUMBER}@container-engine-robot.iam.gserviceaccount.com \
    --role=roles/compute.networkUser

gcloud projects add-iam-policy-binding $VPC_HOST_PROJECT_ID \
    --member=serviceAccount:service-${PROJECT_NUMBER}@container-engine-robot.iam.gserviceaccount.com \
    --role=roles/compute.securityAdmin
```

### Connection Issues

If you can't connect to the cluster:

1. Check master authorized networks:

```bash
gcloud container clusters describe my-gke-cluster \
    --region us-central1 \
    --project your-gke-project-id \
    --format="value(masterAuthorizedNetworksConfig.cidrBlocks)"
```

2. Add your IP to authorized networks in `terraform.tfvars`:

```hcl
master_authorized_networks = [
  {
    cidr_block   = "YOUR_IP/32"
    display_name = "My IP"
  }
]
```

## Security Considerations

- **Private Nodes**: Nodes don't have public IPs
- **Network Policies**: Can be enabled for pod-to-pod traffic control
- **Workload Identity**: Use instead of service account keys
- **Shielded Nodes**: Enabled by default
- **Binary Authorization**: Can be enabled for image verification
- **Master Authorized Networks**: Restrict control plane access

## Cost Optimization

- Use cluster autoscaling to scale down during off-hours
- Consider preemptible nodes for non-critical workloads
- Use regional persistent disks instead of zonal for HA
- Monitor resource utilization with GKE usage metering

## Cleaning Up

To destroy all resources:

```bash
# WARNING: This will delete the cluster and all associated resources
terraform destroy
```

Type `yes` when prompted.

## Support and Contributing

For issues, questions, or contributions:

1. Check the [Terraform GKE documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster)
2. Review [GKE best practices](https://cloud.google.com/kubernetes-engine/docs/best-practices)
3. Consult [Shared VPC documentation](https://cloud.google.com/vpc/docs/shared-vpc)

## License

This module is provided as-is for educational and production use.

## References

- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Shared VPC Overview](https://cloud.google.com/vpc/docs/shared-vpc)
- [Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)
- [GKE Hardening Guide](https://cloud.google.com/kubernetes-engine/docs/how-to/hardening-your-cluster)
