# 🚀 **Google Cloud Workflow - Ansible IAP Deployment Setup Guide**

This guide will help you deploy the Ansible IAP automation workflow and configure it for your environment.

---

## 📋 **Prerequisites**

### **🔧 Required Services & APIs**
```bash
# Enable required Google Cloud APIs
gcloud services enable workflows.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable iap.googleapis.com
gcloud services enable sourcerepo.googleapis.com
```

### **🔑 Required IAM Permissions**
Your service account or user needs these roles:
- `roles/workflows.admin` - Deploy and manage workflows
- `roles/cloudbuild.builds.editor` - Create and manage Cloud Build jobs
- `roles/compute.instanceAdmin` - Manage VMs
- `roles/iap.tunnelResourceAccessor` - IAP tunnel access
- `roles/source.repos.get` - Access source repositories (if using)

---

## 🚀 **Quick Deployment**

### **Step 1: Deploy the Workflow**
```bash
# Navigate to the project directory
cd "Ansible-new-updated-iap copy"

# Deploy the workflow
gcloud workflows deploy ansible-deployment-workflow \
  --source=ansible-deployment-workflow.yaml \
  --location=us-central1 \
  --project=YOUR-PROJECT-ID
```

### **Step 2: Test Basic Execution**
```bash
# Test with default parameters
gcloud workflows run ansible-deployment-workflow \
  --location=us-central1 \
  --project=YOUR-PROJECT-ID \
  --data='{
    "target_vm": "your-vm-name",
    "project_id": "your-project-id",
    "vm_zone": "us-central1-a"
  }'
```

---

## ⚙️ **Configuration for Others**

### **🔄 Step 1: Fork/Clone the Repository**
```bash
# If using GitHub (recommended)
git clone https://github.com/anudishu/ansible-updated-code-iap.git
cd ansible-updated-code-iap

# Update the git_repo parameter in workflow to point to your fork
# Edit ansible-deployment-workflow.yaml line 20:
git_repo: "https://github.com/YOUR-USERNAME/ansible-updated-code-iap.git"
```

### **🎯 Step 2: Customize Default Parameters**

Edit `ansible-deployment-workflow.yaml` and update these default values:

```yaml
# In the 'init' step, update defaults:
- project_id: ${default(map.get(input, "project_id"), "YOUR-PROJECT-ID")}
- target_vm: ${default(map.get(input, "target_vm"), "YOUR-DEFAULT-VM-NAME")}
- vm_zone: ${default(map.get(input, "vm_zone"), "YOUR-DEFAULT-ZONE")}
- ansible_user: ${default(map.get(input, "ansible_user"), "YOUR-SSH-USER")}
- git_repo: ${default(map.get(input, "git_repo"), "YOUR-GIT-REPO-URL")}
```

**🔧 Values to Change:**

| **Parameter** | **Description** | **Example** |
|---------------|-----------------|-------------|
| `YOUR-PROJECT-ID` | Your GCP project ID | `my-company-prod-123` |
| `YOUR-DEFAULT-VM-NAME` | Default VM to target | `production-web-01` |
| `YOUR-DEFAULT-ZONE` | Default GCP zone | `us-east1-a` |
| `YOUR-SSH-USER` | Your SSH username | `myuser_company_com` |
| `YOUR-GIT-REPO-URL` | Your Ansible code repository | `https://github.com/myorg/ansible-project.git` |

---

## 🏭 **Production Configuration Examples**

### **🔐 Option 1: Service Account Authentication**
```yaml
# For production environments using service accounts
- service_account: ${default(map.get(input, "service_account"), "ansible-automation@YOUR-PROJECT.iam.gserviceaccount.com")}
- ansible_user: ${default(map.get(input, "ansible_user"), "sa_SERVICE_ACCOUNT_ID")}
```

### **🌐 Option 2: Multi-Environment Setup**
```yaml
# Support different environments
- environment: ${default(map.get(input, "environment"), "production")}
- project_id: ${if(map.get(input, "environment") == "staging", "staging-project-123", "production-project-456")}
```

### **🎯 Option 3: Custom Playbook Selection**
```yaml
# Allow different playbooks for different scenarios
- playbook: ${default(map.get(input, "playbook"), "golden-image-rhel9.yml")}
- playbook_path: ${default(map.get(input, "playbook_path"), "playbooks/")}
```

---

## 📝 **Usage Examples**

### **🚀 Basic Deployment**
```bash
# Deploy with minimal parameters
gcloud workflows run ansible-deployment-workflow \
  --location=us-central1 \
  --data='{
    "target_vm": "web-server-01",
    "project_id": "my-project-123"
  }'
```

### **🔧 Advanced Deployment**
```bash
# Deploy with full customization
gcloud workflows run ansible-deployment-workflow \
  --location=us-central1 \
  --data='{
    "target_vm": "app-server-02",
    "project_id": "production-project-456",
    "vm_zone": "us-east1-b",
    "playbook": "golden-image-rhel8.yml",
    "ansible_user": "service_account_user",
    "service_account": "ansible-sa@production-project-456.iam.gserviceaccount.com",
    "git_branch": "production",
    "skip_validation": false
  }'
```

### **🎯 Multiple VM Deployment**
```bash
# Deploy to multiple VMs (run in parallel)
for vm in web-01 web-02 app-01; do
  gcloud workflows run ansible-deployment-workflow \
    --location=us-central1 \
    --data="{
      \"target_vm\": \"$vm\",
      \"project_id\": \"my-project-123\"
    }" &
done
wait
```

### **🔄 CI/CD Integration**
```bash
# GitHub Actions / GitLab CI example
name: Deploy Ansible via Workflow
jobs:
  deploy:
    steps:
      - name: Run Ansible Deployment
        run: |
          gcloud workflows run ansible-deployment-workflow \
            --location=us-central1 \
            --data='{
              "target_vm": "${{ github.event.inputs.vm_name }}",
              "project_id": "${{ secrets.GCP_PROJECT_ID }}",
              "playbook": "${{ github.event.inputs.playbook }}",
              "git_branch": "${{ github.ref_name }}"
            }'
```

---

## 🎛️ **Complete Parameter Reference**

### **📋 All Supported Parameters:**

| **Parameter** | **Type** | **Default** | **Description** |
|---------------|----------|-------------|------------------|
| `project_id` | string | `"probable-cove-474504-p0"` | GCP project ID |
| `target_vm` | string | `"ansible-rhel9-vm"` | Target VM name |
| `vm_zone` | string | `"us-central1-a"` | VM zone location |
| `playbook` | string | `"golden-image-rhel9.yml"` | Ansible playbook to run |
| `ansible_user` | string | `"askcloudedge_gmail_com"` | SSH user for VM access |
| `service_account` | string | `""` | Service account for impersonation |
| `git_repo` | string | `"https://github.com/anudishu/..."` | Git repository URL |
| `git_branch` | string | `"master"` | Git branch to use |
| `skip_validation` | boolean | `false` | Skip post-deployment validation |
| `location_id` | string | `"global"` | Cloud Build location |

### **🎯 Parameter Examples:**
```json
{
  "project_id": "my-production-project",
  "target_vm": "web-server-prod-01",
  "vm_zone": "us-central1-a",
  "playbook": "golden-image-rhel9.yml",
  "ansible_user": "ansible_service_user",
  "service_account": "ansible-automation@my-project.iam.gserviceaccount.com",
  "git_repo": "https://github.com/myorg/ansible-infrastructure.git",
  "git_branch": "production",
  "skip_validation": false
}
```

---

## 🔧 **Environment-Specific Setup**

### **🏢 For Your Team/Organization:**

#### **Step 1: Create Organization-Specific Defaults**
```yaml
# Create custom-defaults.yaml
init:
  assign:
    # Your organization's defaults
    - project_id: ${default(map.get(input, "project_id"), "myorg-production-123")}
    - git_repo: ${default(map.get(input, "git_repo"), "https://github.com/myorg/ansible-infrastructure.git")}
    - service_account: ${default(map.get(input, "service_account"), "ansible-prod@myorg-production-123.iam.gserviceaccount.com")}
    - ansible_user: ${default(map.get(input, "ansible_user"), "sa_ansible_service")}
```

#### **Step 2: Deploy Organization Workflow**
```bash
# Deploy with your organization's name
gcloud workflows deploy myorg-ansible-deployment \
  --source=ansible-deployment-workflow.yaml \
  --location=us-central1
```

#### **Step 3: Create Team Usage Guide**
```markdown
# Your Team's Ansible Deployment

## Quick Deploy:
gcloud workflows run myorg-ansible-deployment \
  --location=us-central1 \
  --data='{"target_vm": "YOUR-VM-NAME"}'

## Available VMs:
- web-prod-01, web-prod-02 (Web servers)
- app-prod-01, app-prod-02 (Application servers)  
- db-prod-01 (Database server)

## Available Playbooks:
- golden-image-rhel9.yml (Default - full stack)
- java-only.yml (Java deployment only)
- web-server.yml (Nginx + Node.js)
- database-client.yml (PostgreSQL client only)
```

---

## 🛡️ **Security Configuration**

### **🔐 Service Account Setup**
```bash
# Create dedicated service account for workflows
gcloud iam service-accounts create ansible-workflow-sa \
  --display-name="Ansible Workflow Service Account"

# Grant required permissions
gcloud projects add-iam-policy-binding YOUR-PROJECT-ID \
  --member="serviceAccount:ansible-workflow-sa@YOUR-PROJECT-ID.iam.gserviceaccount.com" \
  --role="roles/cloudbuild.builds.editor"

gcloud projects add-iam-policy-binding YOUR-PROJECT-ID \
  --member="serviceAccount:ansible-workflow-sa@YOUR-PROJECT-ID.iam.gserviceaccount.com" \
  --role="roles/compute.instanceAdmin"
```

### **🔒 IAP Configuration**
```bash
# Ensure IAP is configured for SSH access
gcloud compute project-info add-metadata \
  --metadata enable-oslogin=TRUE

# Create firewall rule for IAP
gcloud compute firewall-rules create allow-iap-ssh \
  --direction=INGRESS \
  --priority=1000 \
  --network=default \
  --action=ALLOW \
  --rules=tcp:22 \
  --source-ranges=35.235.240.0/20
```

---

## 🔍 **Monitoring & Troubleshooting**

### **📊 View Workflow Executions**
```bash
# List recent executions
gcloud workflows executions list ansible-deployment-workflow \
  --location=us-central1 \
  --limit=10

# Get execution details
gcloud workflows executions describe EXECUTION-ID \
  --workflow=ansible-deployment-workflow \
  --location=us-central1
```

### **🔧 View Cloud Build Logs**
```bash
# List recent builds
gcloud builds list --limit=10

# Get build logs
gcloud builds log BUILD-ID
```

### **❌ Common Issues & Solutions**

#### **Issue 1: IAP Connection Failed**
```bash
# Check VM status
gcloud compute instances describe VM-NAME --zone=ZONE

# Test IAP connectivity manually
gcloud compute start-iap-tunnel VM-NAME 22 \
  --local-host-port=localhost:2222 \
  --zone=ZONE

# Verify firewall rules
gcloud compute firewall-rules list --filter="name:iap"
```

#### **Issue 2: Permission Denied**
```bash
# Check service account permissions
gcloud projects get-iam-policy PROJECT-ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:SERVICE-ACCOUNT-EMAIL"

# Add missing permissions
gcloud projects add-iam-policy-binding PROJECT-ID \
  --member="serviceAccount:SERVICE-ACCOUNT-EMAIL" \
  --role="roles/REQUIRED-ROLE"
```

#### **Issue 3: Ansible Playbook Failed**
```bash
# Check playbook syntax locally
ansible-playbook playbooks/golden-image-rhel9.yml --syntax-check

# Test Ansible connection manually
ansible all -i hosts.runtime.yml -m ping -vvv
```

---

## 📈 **Advanced Features**

### **🔄 Workflow Chaining**
```yaml
# Chain multiple workflows together
- web_deployment:
    call: googleapis.workflows.v1.projects.locations.workflows.executions.run
    args:
      name: "projects/PROJECT/locations/us-central1/workflows/ansible-deployment-workflow"
      argument:
        target_vm: "web-server-01"
        playbook: "web-server.yml"

- app_deployment:
    call: googleapis.workflows.v1.projects.locations.workflows.executions.run
    args:
      name: "projects/PROJECT/locations/us-central1/workflows/ansible-deployment-workflow"
      argument:
        target_vm: "app-server-01"
        playbook: "app-server.yml"
```

### **📊 Workflow Monitoring**
```yaml
# Add monitoring and alerting
- notify_success:
    call: googleapis.monitoring.v1.projects.alertPolicies.create
    args:
      # Monitoring configuration
```

### **🎯 Environment-Specific Workflows**
```bash
# Deploy separate workflows for different environments
gcloud workflows deploy ansible-dev-deployment \
  --source=ansible-deployment-workflow.yaml \
  --location=us-central1

gcloud workflows deploy ansible-prod-deployment \
  --source=ansible-deployment-workflow.yaml \
  --location=us-central1
```

---

## 🎉 **Summary for Team Distribution**

### **📋 What Your Team Members Need:**

1. **🔧 Update Configuration** (5 minutes):
   - Edit `ansible-deployment-workflow.yaml` defaults
   - Update project ID, VM names, service accounts
   - Customize git repository URL

2. **🚀 Deploy Workflow** (2 minutes):
   ```bash
   gcloud workflows deploy ansible-deployment-workflow \
     --source=ansible-deployment-workflow.yaml \
     --location=us-central1
   ```

3. **✅ Test Deployment** (5 minutes):
   ```bash
   gcloud workflows run ansible-deployment-workflow \
     --location=us-central1 \
     --data='{"target_vm": "test-vm"}'
   ```

4. **📖 Share Usage Guide**:
   - Provide this document to your team
   - Create team-specific examples
   - Set up monitoring and alerting

---

**🎯 Your Ansible IAP project is now automated with Google Cloud Workflows and ready for enterprise deployment!** 🚀🔐

**Total Setup Time: ~15 minutes | Team Onboarding: ~5 minutes per person**


