#!/bin/bash

# Enable Shared VPC (Organization Admin Only)
# This script must be run by an Organization Admin with the compute.xpnAdmin role

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "=========================================="
echo "  Shared VPC Enablement Script"
echo "  (Organization Admin Only)"
echo "=========================================="
echo ""

# Get VPC host project ID
read -p "Enter the VPC Host Project ID: " VPC_HOST_PROJECT

if [ -z "$VPC_HOST_PROJECT" ]; then
    print_error "VPC Host Project ID is required"
    exit 1
fi

print_info "VPC Host Project: $VPC_HOST_PROJECT"
echo ""

# Check if already enabled by trying to list associated resources
print_info "Checking current Shared VPC status..."
CHECK_OUTPUT=$(gcloud compute shared-vpc list-associated-resources $VPC_HOST_PROJECT 2>&1 || true)

if echo "$CHECK_OUTPUT" | grep -q "is not a shared VPC host project"; then
    print_info "Shared VPC is NOT currently enabled on $VPC_HOST_PROJECT"
elif echo "$CHECK_OUTPUT" | grep -qE "RESOURCE_ID|No resources found"; then
    print_info "Shared VPC is already enabled on $VPC_HOST_PROJECT"
    echo ""
    print_info "You can now attach service projects using:"
    echo "  gcloud compute shared-vpc associated-projects add SERVICE_PROJECT_ID \\"
    echo "    --host-project $VPC_HOST_PROJECT"
    exit 0
else
    print_info "Shared VPC appears to be already enabled on $VPC_HOST_PROJECT"
    echo ""
    print_info "You can now attach service projects using:"
    echo "  gcloud compute shared-vpc associated-projects add SERVICE_PROJECT_ID \\"
    echo "    --host-project $VPC_HOST_PROJECT"
    exit 0
fi

# Confirm before enabling
echo ""
print_info "This will enable Shared VPC on project: $VPC_HOST_PROJECT"
read -p "Do you want to continue? (yes/no): " response

if [ "$response" != "yes" ]; then
    print_error "Operation cancelled"
    exit 1
fi

# Enable Shared VPC
print_info "Enabling Shared VPC on $VPC_HOST_PROJECT..."
if gcloud compute shared-vpc enable $VPC_HOST_PROJECT --project=$VPC_HOST_PROJECT; then
    echo ""
    print_info "✓ Shared VPC enabled successfully on $VPC_HOST_PROJECT"
    echo ""
    print_info "Next steps:"
    echo "  1. Attach service projects using:"
    echo "     gcloud compute shared-vpc associated-projects add SERVICE_PROJECT_ID \\"
    echo "       --host-project $VPC_HOST_PROJECT"
    echo ""
    echo "  2. Or have the user run: make setup"
    echo ""
else
    echo ""
    print_error "Failed to enable Shared VPC"
    echo ""
    echo "Required permissions:"
    echo "  - roles/compute.xpnAdmin (Shared VPC Admin)"
    echo "  - Must be granted at the organization level"
    echo ""
    echo "To grant these permissions, an Organization Admin should run:"
    echo "  gcloud organizations add-iam-policy-binding ORG_ID \\"
    echo "    --member='user:YOUR_EMAIL' \\"
    echo "    --role='roles/compute.xpnAdmin'"
    echo ""
    exit 1
fi
