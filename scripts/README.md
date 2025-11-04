# Setup Scripts

This directory contains helper scripts for setting up the GKE cluster with Shared VPC.

## Scripts

### 1. `setup-shared-vpc.sh`

**Purpose:** Configures Shared VPC for the GKE cluster (regular users)

**When to use:** After creating `terraform.tfvars` and before running Terraform

**Usage:**
```bash
make setup
# or
./scripts/setup-shared-vpc.sh
```

**What it does:**
- Checks if Shared VPC is enabled on the host project
- Attaches the GKE project as a service project
- Verifies the configuration

**Required permissions:**
- `roles/compute.xpnAdmin` on the VPC host project (if enabling Shared VPC)
- `roles/resourcemanager.projectIamAdmin` on both projects

---

### 2. `enable-shared-vpc-admin.sh`

**Purpose:** Enables Shared VPC on the host project (organization admins only)

**When to use:** When you get a permission error like:
```
Required 'compute.organizations.enableXpnHost' permission
```

**Usage:**
```bash
./scripts/enable-shared-vpc-admin.sh
```

**What it does:**
- Enables Shared VPC on the specified host project
- Requires organization-level admin permissions

**Required permissions:**
- `roles/compute.xpnAdmin` (granted at organization level)
- Organization Admin access

**Note:** This script should be run by your GCP Organization Administrator if you don't have org-level permissions.

---

## Troubleshooting

### Permission Error: `compute.organizations.enableXpnHost`

**Problem:** You're trying to enable Shared VPC but don't have organization-level permissions.

**Solution 1 - Ask your Org Admin:**
Share this command with your Organization Admin:

```bash
./scripts/enable-shared-vpc-admin.sh
```

Or they can run directly:
```bash
gcloud compute shared-vpc enable aug18-25-3
```

**Solution 2 - Get permissions:**
Ask your Org Admin to grant you the Shared VPC Admin role:

```bash
gcloud organizations add-iam-policy-binding ORG_ID \
  --member='user:YOUR_EMAIL' \
  --role='roles/compute.xpnAdmin'
```

### Shared VPC Already Enabled

If Shared VPC is already enabled on the host project, you can skip straight to attaching the service project:

```bash
gcloud compute shared-vpc associated-projects add search-and-reco \
  --host-project aug18-25-3
```

Then verify:
```bash
gcloud compute shared-vpc get-host-project search-and-reco
```

---

## Complete Workflow

### If you have org-level permissions:

```bash
# 1. Configure variables
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars

# 2. Run setup (will enable Shared VPC and attach projects)
make setup

# 3. Continue with Terraform
make init
make apply
```

### If you DON'T have org-level permissions:

```bash
# 1. Configure variables
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars

# 2. Ask your Org Admin to enable Shared VPC
# Share: ./scripts/enable-shared-vpc-admin.sh

# 3. Once enabled, attach the service project
make setup

# 4. Continue with Terraform
make init
make apply
```

---

## Reference

### Check Shared VPC Status

```bash
# Check if a project is a Shared VPC host
gcloud compute shared-vpc get-host-project PROJECT_ID

# List all service projects attached to a host
gcloud compute shared-vpc list-associated-resources HOST_PROJECT_ID
```

### Manual Commands

```bash
# Enable Shared VPC (org admin only)
gcloud compute shared-vpc enable HOST_PROJECT_ID

# Attach service project
gcloud compute shared-vpc associated-projects add SERVICE_PROJECT_ID \
  --host-project HOST_PROJECT_ID

# Detach service project (if needed)
gcloud compute shared-vpc associated-projects remove SERVICE_PROJECT_ID \
  --host-project HOST_PROJECT_ID
```
