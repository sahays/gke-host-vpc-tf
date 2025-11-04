# Quick Start Guide

This guide will help you deploy your GKE cluster in 6 steps.

## Prerequisites Checklist

- [ ] Two GCP projects created (VPC host and GKE project)
- [ ] VPC network created with subnet and secondary ranges
- [ ] `gcloud` CLI authenticated with appropriate permissions
- [ ] Terraform >= 1.5.0 installed

**Note:** Shared VPC setup is automated in Step 2!

## Step 1: Configure Your Variables

```bash
# Copy the example file
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
vim terraform.tfvars
```

**Minimum Required Configuration:**

```hcl
gke_project_id                = "your-gke-project-id"
vpc_host_project_id           = "your-vpc-host-project-id"
region                        = "us-central1"
network_name                  = "your-vpc-network-name"
subnet_name                   = "your-subnet-name"
pods_secondary_range_name     = "your-pods-range-name"
services_secondary_range_name = "your-services-range-name"
cluster_name                  = "my-gke-cluster"
```

## Step 2: Setup Shared VPC

The setup script will automatically:
- Check if Shared VPC is enabled on the host project
- Enable it if needed (with your confirmation)
- Attach the GKE project as a service project
- Verify the configuration

```bash
make setup
```

**Required Permissions:**
- `roles/compute.xpnAdmin` on the VPC host project
- `roles/resourcemanager.projectIamAdmin` on both projects

## Step 3: Initialize Terraform

```bash
make init
# or
terraform init
```

## Step 4: Review the Plan

```bash
make plan
# or
terraform plan
```

Review the resources that will be created:
- ✓ API enablements in both projects
- ✓ Service accounts and IAM bindings
- ✓ Cloud NAT and firewall rules
- ✓ GKE cluster with private configuration
- ✓ Node pool with custom E2 instances (16 vCPU, 64GB RAM)

## Step 5: Deploy the Cluster

```bash
make apply
# or
terraform apply
```

Type `yes` when prompted. Deployment takes ~10-15 minutes.

## Step 6: Connect to Your Cluster

```bash
make connect
# or
gcloud container clusters get-credentials my-gke-cluster \
    --region us-central1 \
    --project your-gke-project-id

# Verify
kubectl get nodes
kubectl cluster-info
```

## What Gets Created?

### In GKE Project
- ✓ GKE regional cluster
- ✓ Node pool with E2 custom instances (16 vCPU, 64GB RAM)
- ✓ Node service account with appropriate IAM roles
- ✓ Enabled APIs (container, compute, monitoring, logging, etc.)

### In VPC Host Project
- ✓ Cloud Router
- ✓ Cloud NAT (for private node internet access)
- ✓ Firewall rules (internal traffic, health checks)
- ✓ IAM bindings for GKE service agents

### Features Enabled
- ✓ Private nodes (no public IPs)
- ✓ Workload Identity
- ✓ Cloud Monitoring & Logging
- ✓ Node autoscaling (1-10 nodes per zone)
- ✓ GKE Dataplane V2 (advanced networking)
- ✓ Shielded nodes
- ✓ Auto-repair and auto-upgrade

## Common Customizations

### Change Node Machine Type

Edit `terraform.tfvars`:

```hcl
# Custom E2 with 32 vCPU and 128GB RAM
node_machine_type = "custom-32-131072"

# Or use predefined types
node_machine_type = "n2-standard-16"
```

### Adjust Autoscaling

Edit `terraform.tfvars`:

```hcl
node_min_count = 2   # Min nodes per zone
node_max_count = 20  # Max nodes per zone
```

### Add Master Authorized Networks

Edit `terraform.tfvars`:

```hcl
master_authorized_networks = [
  {
    cidr_block   = "203.0.113.0/24"
    display_name = "Office Network"
  }
]
```

## Deploy a Test Application

```bash
# Create a deployment
kubectl create deployment nginx --image=nginx:latest

# Expose via load balancer
kubectl expose deployment nginx --port=80 --type=LoadBalancer

# Wait for external IP
kubectl get service nginx --watch

# Test
curl http://<EXTERNAL-IP>
```

## Workload Identity Setup

For applications that need to access Google Cloud services:

```bash
# 1. Create Kubernetes service account
kubectl create serviceaccount my-app-ksa -n default

# 2. Create Google service account
gcloud iam service-accounts create my-app-gsa \
    --project=your-gke-project-id

# 3. Grant GCP permissions (example: Cloud Storage)
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

# 6. Use in your deployment
# Add to pod spec:
#   serviceAccountName: my-app-ksa
```

## Useful Commands

```bash
# Format Terraform files
make fmt

# Validate configuration
make validate

# View outputs
terraform output

# Get specific output
terraform output cluster_name

# View cluster details
gcloud container clusters describe my-gke-cluster \
    --region us-central1 \
    --project your-gke-project-id

# View node pools
gcloud container node-pools list \
    --cluster my-gke-cluster \
    --region us-central1 \
    --project your-gke-project-id

# Scale node pool manually
kubectl scale deployment nginx --replicas=5

# View pod distribution
kubectl get pods -o wide
```

## Troubleshooting

### Can't connect to cluster?

Check master authorized networks:

```bash
gcloud container clusters describe my-gke-cluster \
    --region us-central1 \
    --project your-gke-project-id \
    --format="value(masterAuthorizedNetworksConfig.cidrBlocks)"
```

Add your IP to `terraform.tfvars` and apply.

### API not enabled errors?

```bash
gcloud services enable container.googleapis.com \
    --project=your-gke-project-id
```

### Shared VPC permission issues?

Verify service project attachment:

```bash
gcloud compute shared-vpc get-host-project your-gke-project-id
```

## Cleanup

To destroy all resources:

```bash
make destroy
# or
terraform destroy
```

Type `yes` to confirm. This will delete:
- GKE cluster and all workloads
- Node pools
- Cloud NAT
- Firewall rules
- Service accounts

**Note:** This does NOT delete:
- VPC network or subnets (in host project)
- Any persistent volumes or load balancers created by Kubernetes

## Next Steps

1. **Set up CI/CD**: Integrate with Cloud Build or GitHub Actions
2. **Configure monitoring**: Set up dashboards and alerts
3. **Deploy ingress controller**: Use NGINX or GKE Ingress
4. **Set up backup**: Enable GKE Backup for cluster protection
5. **Implement GitOps**: Use tools like ArgoCD or Flux

## Resources

- [Full README](./README.md)
- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [Workload Identity Guide](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)
- [GKE Best Practices](https://cloud.google.com/kubernetes-engine/docs/best-practices)

## Support

For issues or questions, refer to:
- README.md (detailed documentation)
- Terraform configuration files (inline comments)
- GCP support or community forums
