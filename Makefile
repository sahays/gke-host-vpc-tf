.PHONY: help setup init plan apply destroy validate fmt clean connect

# Default target
help:
	@echo "Available targets:"
	@echo "  setup      - Configure Shared VPC (run this first!)"
	@echo "  init       - Initialize Terraform"
	@echo "  validate   - Validate Terraform configuration"
	@echo "  fmt        - Format Terraform files"
	@echo "  plan       - Show execution plan"
	@echo "  apply      - Apply Terraform configuration"
	@echo "  destroy    - Destroy all resources (use with caution!)"
	@echo "  clean      - Remove Terraform state and cache"
	@echo "  connect    - Get kubectl credentials for the cluster"
	@echo ""
	@echo "First time setup:"
	@echo "  1. cp terraform.tfvars.example terraform.tfvars"
	@echo "  2. Edit terraform.tfvars with your values"
	@echo "  3. make setup   (configure Shared VPC)"
	@echo "  4. make init    (initialize Terraform)"
	@echo "  5. make apply   (deploy the cluster)"
	@echo ""
	@echo "Usage: make <target>"

# Configure Shared VPC
setup:
	@echo "Configuring Shared VPC..."
	@if [ ! -f terraform.tfvars ]; then \
		echo "Error: terraform.tfvars not found."; \
		echo "Please copy terraform.tfvars.example to terraform.tfvars and fill in your values."; \
		exit 1; \
	fi
	@chmod +x scripts/setup-shared-vpc.sh
	@./scripts/setup-shared-vpc.sh

# Initialize Terraform
init:
	@echo "Checking Shared VPC configuration..."
	@if [ -f terraform.tfvars ]; then \
		VPC_HOST=$$(grep '^vpc_host_project_id' terraform.tfvars | cut -d'"' -f2); \
		GKE_PROJ=$$(grep '^gke_project_id' terraform.tfvars | cut -d'"' -f2); \
		if [ -n "$$VPC_HOST" ] && [ -n "$$GKE_PROJ" ]; then \
			CURRENT_HOST=$$(gcloud compute shared-vpc get-host-project $$GKE_PROJ 2>/dev/null || echo ""); \
			if [ "$$CURRENT_HOST" != "$$VPC_HOST" ]; then \
				echo "⚠️  Shared VPC not configured properly."; \
				echo ""; \
				echo "Run 'make setup' to configure Shared VPC, or continue without it."; \
				read -p "Configure Shared VPC now? (yes/no): " answer; \
				if [ "$$answer" = "yes" ]; then \
					$(MAKE) setup; \
				fi; \
			else \
				echo "✓ Shared VPC is configured correctly"; \
			fi; \
		fi; \
	fi
	@echo "Initializing Terraform..."
	terraform init

# Validate configuration
validate: init
	@echo "Validating Terraform configuration..."
	terraform validate

# Format Terraform files
fmt:
	@echo "Formatting Terraform files..."
	terraform fmt -recursive

# Show execution plan
plan: validate
	@echo "Generating execution plan..."
	terraform plan

# Apply configuration
apply: validate
	@echo "Applying Terraform configuration..."
	terraform apply

# Destroy resources
destroy:
	@echo "WARNING: This will destroy all resources!"
	@echo "Press Ctrl+C to cancel, or"
	@read -p "Type 'yes' to continue: " confirm && [ "$$confirm" = "yes" ]
	terraform destroy

# Clean Terraform state and cache
clean:
	@echo "Cleaning Terraform state and cache..."
	rm -rf .terraform/
	rm -f .terraform.lock.hcl
	rm -f terraform.tfstate*
	@echo "Clean complete. Run 'make init' to reinitialize."

# Get kubectl credentials
connect:
	@echo "Getting kubectl credentials..."
	@if [ ! -f terraform.tfvars ]; then \
		echo "Error: terraform.tfvars not found. Please create it first."; \
		exit 1; \
	fi
	@GKE_PROJECT=$$(grep '^gke_project_id' terraform.tfvars | cut -d'"' -f2); \
	CLUSTER_NAME=$$(grep '^cluster_name' terraform.tfvars | cut -d'"' -f2); \
	REGION=$$(grep '^region' terraform.tfvars | cut -d'"' -f2); \
	if [ -z "$$GKE_PROJECT" ] || [ -z "$$CLUSTER_NAME" ] || [ -z "$$REGION" ]; then \
		echo "Error: Could not extract configuration from terraform.tfvars"; \
		exit 1; \
	fi; \
	gcloud container clusters get-credentials $$CLUSTER_NAME \
		--region $$REGION \
		--project $$GKE_PROJECT
	@echo ""
	@echo "Testing connection..."
	kubectl get nodes
