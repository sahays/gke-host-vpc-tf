#!/bin/bash

# Setup Shared VPC for GKE Cluster
# This script configures the shared VPC relationship between the host and service projects

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if terraform.tfvars exists
if [ ! -f terraform.tfvars ]; then
    print_error "terraform.tfvars not found. Please create it from terraform.tfvars.example"
    exit 1
fi

# Extract project IDs from terraform.tfvars
print_info "Reading configuration from terraform.tfvars..."
VPC_HOST_PROJECT=$(grep '^vpc_host_project_id' terraform.tfvars | cut -d'"' -f2)
GKE_PROJECT=$(grep '^gke_project_id' terraform.tfvars | cut -d'"' -f2)

if [ -z "$VPC_HOST_PROJECT" ] || [ -z "$GKE_PROJECT" ]; then
    print_error "Could not extract project IDs from terraform.tfvars"
    print_error "Please ensure vpc_host_project_id and gke_project_id are set"
    exit 1
fi

print_info "VPC Host Project: $VPC_HOST_PROJECT"
print_info "GKE Project: $GKE_PROJECT"

# Check if shared VPC is already enabled on host project
print_info "Checking if Shared VPC is enabled on host project..."
HOST_CHECK=$(gcloud compute shared-vpc list-associated-resources $VPC_HOST_PROJECT 2>&1 || true)

if echo "$HOST_CHECK" | grep -q "is not a shared VPC host project"; then
    print_warn "Shared VPC is not enabled on $VPC_HOST_PROJECT"
    echo ""
    print_warn "Enabling Shared VPC requires organization-level permissions:"
    echo "  - compute.organizations.enableXpnHost"
    echo "  - resourcemanager.projects.get"
    echo ""
    print_info "You have two options:"
    echo "  1. Ask your Organization Admin to enable Shared VPC"
    echo "  2. Enable it yourself if you have the required permissions"
    echo ""
    read -p "Do you have organization admin permissions to enable Shared VPC? (yes/no): " response
    if [ "$response" = "yes" ]; then
        print_info "Attempting to enable Shared VPC on $VPC_HOST_PROJECT..."
        if gcloud compute shared-vpc enable $VPC_HOST_PROJECT --project=$VPC_HOST_PROJECT 2>&1; then
            print_info "Shared VPC enabled successfully"
        else
            print_error "Failed to enable Shared VPC. You may need to:"
            echo ""
            echo "Ask your Organization Admin to run:"
            echo "  gcloud compute shared-vpc enable $VPC_HOST_PROJECT"
            echo ""
            echo "Or use the helper script:"
            echo "  ./scripts/enable-shared-vpc-admin.sh"
            echo ""
            echo "Or grant yourself the 'Shared VPC Admin' role at the organization level:"
            echo "  gcloud organizations add-iam-policy-binding ORG_ID \\"
            echo "    --member='user:YOUR_EMAIL' \\"
            echo "    --role='roles/compute.xpnAdmin'"
            echo ""
            exit 1
        fi
    else
        print_error "Please ask your Organization Admin to enable Shared VPC:"
        echo ""
        echo "Option 1 - Use the helper script:"
        echo "  ./scripts/enable-shared-vpc-admin.sh"
        echo ""
        echo "Option 2 - Run directly:"
        echo "  gcloud compute shared-vpc enable $VPC_HOST_PROJECT"
        echo ""
        echo "Once enabled, run 'make setup' again to continue."
        exit 1
    fi
else
    print_info "Shared VPC is already enabled on $VPC_HOST_PROJECT"
fi

# Check if service project is already attached
print_info "Checking if $GKE_PROJECT is attached to Shared VPC..."
CURRENT_HOST=$(gcloud compute shared-vpc get-host-project $GKE_PROJECT 2>/dev/null || echo "")

# Clean up the response - extract project ID from various formats
# Format can be: "aug18-25-3" or "kind:compute#projectname:aug18-25-3" or "{}"
CURRENT_HOST=$(echo "$CURRENT_HOST" | tr -d '{}' | tr -d ' ' | tr -d '\n')
# If it contains "projectname:", extract just the project ID after it
if echo "$CURRENT_HOST" | grep -q "projectname:"; then
    CURRENT_HOST=$(echo "$CURRENT_HOST" | sed 's/.*projectname://')
fi

if [ "$CURRENT_HOST" = "$VPC_HOST_PROJECT" ]; then
    print_info "Service project $GKE_PROJECT is already attached to $VPC_HOST_PROJECT"
elif [ -n "$CURRENT_HOST" ]; then
    print_warn "$GKE_PROJECT is currently attached to a different host: $CURRENT_HOST"
    read -p "Would you like to detach and reattach to $VPC_HOST_PROJECT? (yes/no): " response
    if [ "$response" != "yes" ]; then
        print_error "Cannot proceed without proper Shared VPC configuration. Exiting."
        exit 1
    fi
    print_info "Detaching from $CURRENT_HOST..."
    gcloud compute shared-vpc associated-projects remove $GKE_PROJECT \
        --host-project $CURRENT_HOST

    print_info "Attaching $GKE_PROJECT to Shared VPC host $VPC_HOST_PROJECT..."
    gcloud compute shared-vpc associated-projects add $GKE_PROJECT \
        --host-project $VPC_HOST_PROJECT
    print_info "Service project attached successfully"
else
    print_info "$GKE_PROJECT is not currently attached to any Shared VPC"
    print_info "Attaching $GKE_PROJECT to Shared VPC host $VPC_HOST_PROJECT..."
    gcloud compute shared-vpc associated-projects add $GKE_PROJECT \
        --host-project $VPC_HOST_PROJECT
    print_info "Service project attached successfully"
fi

# Verify the setup
print_info "Verifying Shared VPC configuration..."
VERIFIED_HOST=$(gcloud compute shared-vpc get-host-project $GKE_PROJECT 2>/dev/null || echo "")

# Clean up the response - extract project ID from various formats
VERIFIED_HOST=$(echo "$VERIFIED_HOST" | tr -d '{}' | tr -d ' ' | tr -d '\n')
# If it contains "projectname:", extract just the project ID after it
if echo "$VERIFIED_HOST" | grep -q "projectname:"; then
    VERIFIED_HOST=$(echo "$VERIFIED_HOST" | sed 's/.*projectname://')
fi

if [ "$VERIFIED_HOST" = "$VPC_HOST_PROJECT" ]; then
    print_info "✓ Shared VPC configuration verified successfully"
    echo ""
    print_info "Configuration Summary:"
    echo "  Host Project: $VPC_HOST_PROJECT"
    echo "  Service Project: $GKE_PROJECT"
    echo "  Status: Attached"
    echo ""
    print_info "You can now proceed with: terraform init && terraform apply"
else
    print_error "Shared VPC configuration verification failed"
    echo "  Expected host: $VPC_HOST_PROJECT"
    echo "  Actual host: '$VERIFIED_HOST'"
    echo ""
    print_info "Trying to verify using list command..."
    if gcloud compute shared-vpc list-associated-resources $VPC_HOST_PROJECT 2>&1 | grep -q "$GKE_PROJECT"; then
        print_info "✓ Verified: $GKE_PROJECT is listed as an associated resource"
        echo ""
        print_info "Configuration Summary:"
        echo "  Host Project: $VPC_HOST_PROJECT"
        echo "  Service Project: $GKE_PROJECT"
        echo "  Status: Attached"
        echo ""
        print_info "You can now proceed with: terraform init && terraform apply"
    else
        print_error "Could not verify Shared VPC attachment. Please check manually:"
        echo "  gcloud compute shared-vpc get-host-project $GKE_PROJECT"
        exit 1
    fi
fi
