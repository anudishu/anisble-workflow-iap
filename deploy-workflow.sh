#!/bin/bash

# =========================================================================
# ANSIBLE IAP WORKFLOW - DEPLOYMENT SCRIPT
# =========================================================================
# This script automates the deployment of the Ansible IAP workflow
# 
# Usage: ./deploy-workflow.sh [project-id] [location]
# Example: ./deploy-workflow.sh my-project-123 us-central1
# =========================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
DEFAULT_PROJECT=$(gcloud config get-value project 2>/dev/null || echo "")
DEFAULT_LOCATION="us-central1"
WORKFLOW_NAME="ansible-deployment-workflow"
WORKFLOW_FILE="ansible-deployment-workflow.yaml"

# Parse command line arguments
PROJECT_ID="${1:-$DEFAULT_PROJECT}"
LOCATION="${2:-$DEFAULT_LOCATION}"

# Helper functions
print_header() {
    echo -e "${BLUE}==========================================================================${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}==========================================================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check if gcloud is installed and authenticated
    if ! command -v gcloud &> /dev/null; then
        print_error "gcloud CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check if authenticated
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        print_error "Not authenticated with gcloud. Run: gcloud auth login"
        exit 1
    fi
    
    # Check project ID
    if [ -z "$PROJECT_ID" ]; then
        print_error "Project ID is required. Usage: $0 <project-id> [location]"
        exit 1
    fi
    
    # Verify project exists and is accessible
    if ! gcloud projects describe "$PROJECT_ID" &>/dev/null; then
        print_error "Cannot access project: $PROJECT_ID"
        print_info "Available projects:"
        gcloud projects list --format="table(projectId,name)"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
    print_info "Project: $PROJECT_ID"
    print_info "Location: $LOCATION"
}

# Enable required APIs
enable_apis() {
    print_header "Enabling Required APIs"
    
    local apis=(
        "workflows.googleapis.com"
        "cloudbuild.googleapis.com"
        "compute.googleapis.com"
        "iap.googleapis.com"
        "sourcerepo.googleapis.com"
    )
    
    for api in "${apis[@]}"; do
        print_info "Enabling $api..."
        gcloud services enable "$api" --project="$PROJECT_ID" || {
            print_warning "Failed to enable $api (might already be enabled)"
        }
    done
    
    print_success "APIs enabled successfully"
}

# Check IAM permissions
check_permissions() {
    print_header "Checking IAM Permissions"
    
    local current_user
    current_user=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")
    
    print_info "Current user: $current_user"
    
    # Check if user has workflows admin role
    if gcloud projects get-iam-policy "$PROJECT_ID" --flatten="bindings[].members" \
       --filter="bindings.members:user:$current_user AND bindings.role:roles/workflows.admin" \
       --format="value(bindings.role)" | grep -q workflows.admin; then
        print_success "Workflows admin permissions confirmed"
    else
        print_warning "Workflows admin role not detected. You may need additional permissions."
        print_info "Required roles: roles/workflows.admin, roles/cloudbuild.builds.editor"
    fi
}

# Customize workflow file
customize_workflow() {
    print_header "Customizing Workflow Configuration"
    
    if [ ! -f "$WORKFLOW_FILE" ]; then
        print_error "Workflow file not found: $WORKFLOW_FILE"
        print_info "Please ensure you're in the correct directory with the workflow file."
        exit 1
    fi
    
    # Create a backup
    cp "$WORKFLOW_FILE" "${WORKFLOW_FILE}.backup"
    print_info "Created backup: ${WORKFLOW_FILE}.backup"
    
    # Update default project ID in workflow file
    if grep -q '"probable-cove-474504-p0"' "$WORKFLOW_FILE"; then
        sed -i.tmp "s/probable-cove-474504-p0/$PROJECT_ID/g" "$WORKFLOW_FILE"
        rm -f "${WORKFLOW_FILE}.tmp"
        print_success "Updated default project ID to: $PROJECT_ID"
    fi
    
    print_info "Workflow file customized for your environment"
}

# Deploy workflow
deploy_workflow() {
    print_header "Deploying Workflow"
    
    print_info "Deploying workflow: $WORKFLOW_NAME"
    print_info "Location: $LOCATION"
    print_info "Project: $PROJECT_ID"
    
    if gcloud workflows deploy "$WORKFLOW_NAME" \
        --source="$WORKFLOW_FILE" \
        --location="$LOCATION" \
        --project="$PROJECT_ID"; then
        print_success "Workflow deployed successfully!"
    else
        print_error "Workflow deployment failed"
        exit 1
    fi
}

# Test workflow
test_workflow() {
    print_header "Testing Workflow Deployment"
    
    # Check if workflow exists
    if gcloud workflows describe "$WORKFLOW_NAME" \
        --location="$LOCATION" \
        --project="$PROJECT_ID" &>/dev/null; then
        print_success "Workflow is accessible and ready"
    else
        print_error "Workflow deployment verification failed"
        exit 1
    fi
    
    print_info "Workflow URL: https://console.cloud.google.com/workflows/workflow/$LOCATION/$WORKFLOW_NAME?project=$PROJECT_ID"
}

# Generate usage examples
generate_usage_examples() {
    print_header "Usage Examples"
    
    cat << EOF

${GREEN}🎉 Workflow Deployed Successfully!${NC}

${BLUE}📋 Basic Usage:${NC}
gcloud workflows run $WORKFLOW_NAME \\
  --location=$LOCATION \\
  --project=$PROJECT_ID \\
  --data='{
    "target_vm": "your-vm-name",
    "vm_zone": "us-central1-a"
  }'

${BLUE}📋 Advanced Usage:${NC}
gcloud workflows run $WORKFLOW_NAME \\
  --location=$LOCATION \\
  --project=$PROJECT_ID \\
  --data='{
    "target_vm": "production-web-01",
    "vm_zone": "us-central1-a",
    "playbook": "golden-image-rhel9.yml",
    "ansible_user": "your-ssh-user",
    "service_account": "ansible-sa@$PROJECT_ID.iam.gserviceaccount.com"
  }'

${BLUE}📋 Monitor Executions:${NC}
gcloud workflows executions list $WORKFLOW_NAME \\
  --location=$LOCATION \\
  --project=$PROJECT_ID

${BLUE}📋 View Execution Details:${NC}
gcloud workflows executions describe EXECUTION-ID \\
  --workflow=$WORKFLOW_NAME \\
  --location=$LOCATION \\
  --project=$PROJECT_ID

${YELLOW}📖 For complete documentation, see: WORKFLOW-SETUP-GUIDE.md${NC}

EOF
}

# Cleanup function
cleanup() {
    if [ -f "${WORKFLOW_FILE}.backup" ]; then
        print_info "Restoring original workflow file..."
        mv "${WORKFLOW_FILE}.backup" "$WORKFLOW_FILE"
    fi
}

# Set trap for cleanup
trap cleanup EXIT

# Main execution
main() {
    print_header "Ansible IAP Workflow Deployment"
    
    echo -e "${BLUE}This script will:${NC}"
    echo -e "${BLUE}1. Check prerequisites and permissions${NC}"
    echo -e "${BLUE}2. Enable required Google Cloud APIs${NC}"
    echo -e "${BLUE}3. Customize the workflow for your project${NC}"
    echo -e "${BLUE}4. Deploy the workflow to Google Cloud${NC}"
    echo -e "${BLUE}5. Verify deployment and provide usage examples${NC}"
    echo
    
    read -p "Continue with deployment? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Deployment cancelled by user"
        exit 0
    fi
    
    check_prerequisites
    enable_apis
    check_permissions
    customize_workflow
    deploy_workflow
    test_workflow
    generate_usage_examples
    
    print_header "Deployment Complete"
    print_success "Ansible IAP Workflow is ready for use!"
}

# Run main function
main "$@"


