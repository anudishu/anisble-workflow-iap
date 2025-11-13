# Ansible IAP Deployment Automation

Fully automated Ansible deployment system using Google Cloud Build, Workflows, and Identity-Aware Proxy (IAP) for secure VM access.

---

## 📁 Project Structure

```
Ansible-new-updated-iap copy/
├── README.md                           # This comprehensive guide
├── ansible.cfg                         # Ansible configuration
├── hosts.runtime.yml                   # Local inventory (IAP-enabled)
├── ansible-workflow-cloudbuild.yaml    # Workflow definition
├── cloudbuild.yaml                     # Cloud Build configuration
│
├── playbooks/                          # Ansible playbooks
│   ├── golden-image-rhel7.yml         # RHEL 7 golden image
│   ├── golden-image-rhel8.yml         # RHEL 8 golden image
│   ├── golden-image-rhel9.yml         # RHEL 9 golden image (default)
│   ├── site.yml                       # Master playbook
│   └── README.md                      # Playbook documentation
│
├── roles/                              # Ansible roles
│   ├── install-java-sdk/              # Java 17 OpenJDK installation
│   │   ├── handlers/
│   │   └── tasks/main.yml
│   ├── install-nodejs/                # Node.js 18 LTS via NodeSource
│   │   ├── handlers/
│   │   └── tasks/main.yml
│   ├── install-python/                # Python 3.9+ with pip
│   │   ├── handlers/
│   │   └── tasks/main.yml
│   └── install-database-cient/        # PostgreSQL client
│       ├── handlers/
│       └── tasks/main.yml
│
├── vars/                               # OS-specific variables
│   ├── rhel7.yml                      # RHEL 7 vars
│   ├── rhel8.yml                      # RHEL 8 vars
│   └── rhel9.yml                      # RHEL 9 vars (Java 17, Node 18, Python 3.9, PostgreSQL 15)
│
├── validation/                         # Post-deployment validation
│   ├── validate_all.sh                # Master validation script
│   ├── validate_java.sh               # Java validation
│   ├── validate_node.sh               # Node.js validation
│   ├── validate_python.sh             # Python validation
│   ├── validate_postgresql.sh         # PostgreSQL client validation
│   ├── validate.yml                   # Validation playbook
│   └── README.md                      # Validation documentation
│
├── scripts/                            # Utility scripts
│   ├── render_hosts_iap.sh            # Dynamic inventory generator
│   └── README.md                      # Scripts documentation
│
└── roles-template/                     # Template for creating new roles
    ├── defaults/main.yml
    ├── handlers/
    ├── meta/main.yml
    └── tasks/
        ├── main.yml
        ├── rhel7.yml
        └── rhel8_9.yml
```

---

## 🎯 Three Deployment Methods

### **Method 1: Workflow + Cloud Build** (Production)
Best for: CI/CD, scheduled deployments, team collaboration

```bash
gcloud workflows run ansible-cloudbuild-workflow \
  --data='{"playbook":"golden-image-rhel9.yml","target_vm":"ansible-rhel9-vm"}' \
  --location=us-central1
```

- ✅ Pulls code from GitHub automatically
- ✅ Full orchestration with error handling
- ✅ Perfect for production and CI/CD

### **Method 2: Direct Cloud Build** (Testing)
Best for: Quick testing with local changes

```bash
cd "Ansible-new-updated-iap copy"
gcloud builds submit . --config=cloudbuild.yaml
```

- ✅ Uses local files (no Git push)
- ✅ Faster testing cycle
- ✅ Good for development

### **Method 3: Local Ansible** (Development)
Best for: Development and debugging

```bash
ansible-playbook -i hosts.runtime.yml playbooks/golden-image-rhel9.yml
```

- ✅ Immediate feedback
- ✅ Best for debugging
- ✅ Direct execution

---

## 📋 Setup Flow Overview

```
FIRST-TIME SETUP (One Time)
═══════════════════════════════════════════════════════════════

1. Generate SSH Key Pair
   ├─→ Private Key: ~/.ssh/ansible_test_key (keep secret!)
   └─→ Public Key: ~/.ssh/ansible_test_key.pub (add to VM)

2. Enable Google Cloud APIs
   └─→ Compute, Cloud Build, Workflows, Secret Manager, IAP

3. Create Service Account
   └─→ ansible-automation@PROJECT_ID.iam.gserviceaccount.com

4. Grant IAM Permissions (7 roles)
   ├─→ Cloud Build Editor
   ├─→ Compute Instance Admin
   ├─→ IAP Tunnel Resource Accessor
   ├─→ Secret Manager Accessor
   ├─→ Storage Object Admin
   ├─→ Logging Writer
   └─→ Service Account User

5. Store SSH Private Key in Secret Manager
   └─→ Secret: ansible-ssh-private-key (encrypted)

6. Configure Cloud NAT
   └─→ Provides VM internet access (for package downloads)

7. Create Target VM
   ├─→ No external IP (security)
   └─→ Add public SSH key to VM metadata

8. Deploy Workflow
   └─→ Upload workflow definition to Google Cloud

═══════════════════════════════════════════════════════════════

DAILY USAGE (Anytime)
═══════════════════════════════════════════════════════════════

One command to deploy:
$ gcloud workflows run ansible-cloudbuild-workflow \
    --data='{"playbook":"golden-image-rhel9.yml"}' \
    --location=us-central1

All automation happens:
  ✓ Code pulled from GitHub
  ✓ SSH key retrieved from Secret Manager
  ✓ IAP tunnel established
  ✓ Ansible deployed
  ✓ Validation run
  ✓ Results returned

═══════════════════════════════════════════════════════════════
```

---

## 🚀 Complete Setup Guide

### Prerequisites

```bash
# Set project
export PROJECT_ID="probable-cove-474504-p0"
gcloud config set project $PROJECT_ID

# Set service account email (will be created in Step 2)
export SA_EMAIL="ansible-automation@${PROJECT_ID}.iam.gserviceaccount.com"
```

---

### 🔑 Quick Setup: SSH Key Generation (First-Time Setup)

If you don't have an SSH key yet, generate one first:

```bash
# 1. Generate SSH key pair (choose one method)
# Method A: ED25519 (recommended - more secure, faster)
ssh-keygen -t ed25519 -f ~/.ssh/ansible_test_key -C "ansible-automation" -N ""

# Method B: RSA 4096 (traditional, widely supported)
ssh-keygen -t rsa -b 4096 -f ~/.ssh/ansible_test_key -C "ansible-automation" -N ""

# 2. Verify keys were created
ls -lh ~/.ssh/ansible_test_key*
# Output:
# ansible_test_key       <- Private key (keep secret!)
# ansible_test_key.pub   <- Public key (safe to share)

# 3. View public key (you'll need this later)
cat ~/.ssh/ansible_test_key.pub
```

**💡 Key Points:**
- **Private key** (`ansible_test_key`): Never share! Will be stored in Secret Manager
- **Public key** (`ansible_test_key.pub`): Added to VM metadata for SSH access
- **No passphrase** (`-N ""`): Required for automated deployments

---

### Step 1: Enable Required APIs

```bash
# Enable all required APIs
gcloud services enable compute.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable workflows.googleapis.com
gcloud services enable secretmanager.googleapis.com
gcloud services enable iap.googleapis.com
```

### Step 2: Create Service Account

```bash
# Create service account
gcloud iam service-accounts create ansible-automation \
  --display-name="Ansible Automation Service Account" \
  --description="Service account for automated Ansible deployments"

# Set service account variable
export SA_EMAIL="ansible-automation@${PROJECT_ID}.iam.gserviceaccount.com"
```

### Step 3: Grant IAM Permissions

```bash
# Cloud Build permissions
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/cloudbuild.builds.editor"

# Compute permissions
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/compute.instanceAdmin"

# IAP Tunnel access
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/iap.tunnelResourceAccessor"

# Secret Manager access
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/secretmanager.secretAccessor"

# Storage access (for Cloud Build)
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/storage.objectAdmin"

# Logging
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/logging.logWriter"

# Allow service account to act as itself
gcloud iam service-accounts add-iam-policy-binding ${SA_EMAIL} \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/iam.serviceAccountUser"
```

### Step 4: Generate SSH Key and Store in Secret Manager

#### 4.1: Generate SSH Key Pair

```bash
# Generate ED25519 SSH key (recommended - more secure and faster)
ssh-keygen -t ed25519 \
  -f "${HOME}/.ssh/ansible_test_key" \
  -C "ansible-automation" \
  -N ""

# OR generate RSA key (if ED25519 not supported)
ssh-keygen -t rsa -b 4096 \
  -f "${HOME}/.ssh/ansible_test_key" \
  -C "ansible-automation" \
  -N ""

# Verify key was created
ls -lh ~/.ssh/ansible_test_key*
# You should see:
# ansible_test_key       (private key)
# ansible_test_key.pub   (public key)

# View public key (you'll need this for VM metadata)
cat ~/.ssh/ansible_test_key.pub
```

**Parameters explained:**
- `-t ed25519` or `-t rsa -b 4096`: Key type and size
- `-f`: Output file path
- `-C`: Comment (identifies the key)
- `-N ""`: Empty passphrase (required for automation)

#### 4.2: Store Private Key in Secret Manager

```bash
# Create secret from your SSH private key
gcloud secrets create ansible-ssh-private-key \
  --data-file="${HOME}/.ssh/ansible_test_key" \
  --replication-policy="automatic"

# Grant service account access to the secret
gcloud secrets add-iam-policy-binding ansible-ssh-private-key \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/secretmanager.secretAccessor"

# Verify secret was created
gcloud secrets describe ansible-ssh-private-key

# Test secret retrieval (optional)
gcloud secrets versions access latest --secret="ansible-ssh-private-key" | head -n 1
```

**⚠️ Security Note:**
- Private key stored in Secret Manager (encrypted at rest)
- Only service account can access the secret
- Never commit private keys to Git
- Public key is safe to share/store in VM metadata

### Step 5: Configure Cloud NAT (for VM Internet Access)

VMs without external IPs need Cloud NAT to download packages from the internet.

```bash
# Create Cloud Router
gcloud compute routers create nat-router \
  --network=default \
  --region=us-central1

# Create Cloud NAT
gcloud compute routers nats create nat-config \
  --router=nat-router \
  --region=us-central1 \
  --auto-allocate-nat-external-ips \
  --nat-all-subnet-ip-ranges

# Verify Cloud NAT
gcloud compute routers nats list --router=nat-router --region=us-central1
```

### Step 6: Create Target VM (if needed)

```bash
# Create VM without external IP
gcloud compute instances create ansible-rhel9-vm \
  --zone=us-central1-a \
  --machine-type=e2-medium \
  --image-family=rhel-9 \
  --image-project=rhel-cloud \
  --boot-disk-size=20GB \
  --boot-disk-type=pd-standard \
  --no-address \
  --metadata=enable-oslogin=TRUE

# Add your SSH key to the VM
gcloud compute instances add-metadata ansible-rhel9-vm \
  --zone=us-central1-a \
  --metadata-from-file ssh-keys=<(echo "askcloudedge_gmail_com:$(cat ~/.ssh/ansible_test_key.pub)")

# Grant IAP access to your user account
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="user:askcloudedge@gmail.com" \
  --role="roles/iap.tunnelResourceAccessor"
```

### Step 7: Deploy Workflow

```bash
# Navigate to project directory
cd "Ansible-new-updated-iap copy"

# Deploy the workflow
gcloud workflows deploy ansible-cloudbuild-workflow \
  --source=ansible-workflow-cloudbuild.yaml \
  --location=us-central1 \
  --service-account=${SA_EMAIL}

# Verify workflow deployment
gcloud workflows describe ansible-cloudbuild-workflow --location=us-central1
```

### Step 8: Test Deployment

```bash
# Test with workflow (production method)
gcloud workflows run ansible-cloudbuild-workflow \
  --data='{"playbook":"golden-image-rhel9.yml","target_vm":"ansible-rhel9-vm"}' \
  --location=us-central1
```

---

## 📖 Deployment Usage

### Using Workflow (Recommended)

#### Basic Deployment
```bash
gcloud workflows run ansible-cloudbuild-workflow \
  --data='{"playbook":"golden-image-rhel9.yml"}' \
  --location=us-central1
```

#### Custom Parameters
```bash
gcloud workflows run ansible-cloudbuild-workflow \
  --data='{
    "target_vm": "my-vm",
    "vm_zone": "us-west1-a",
    "playbook": "golden-image-rhel8.yml",
    "git_branch": "develop"
  }' \
  --location=us-central1
```

#### Available Parameters
- `project_id`: GCP project (default: `probable-cove-474504-p0`)
- `target_vm`: Target VM name (default: `ansible-rhel9-vm`)
- `vm_zone`: VM zone (default: `us-central1-a`)
- `playbook`: Playbook to run (default: `golden-image-rhel9.yml`)
- `git_repo`: GitHub repo (default: `https://github.com/anudishu/anisble-workflow-iap.git`)
- `git_branch`: Git branch (default: `master`)

### Using Cloud Build (Testing)

```bash
# Basic deployment
cd "Ansible-new-updated-iap copy"
gcloud builds submit . --config=cloudbuild.yaml

# With custom substitutions
gcloud builds submit . --config=cloudbuild.yaml \
  --substitutions=_TARGET_VM=my-vm,_VM_ZONE=us-west1-a,_PLAYBOOK=golden-image-rhel8.yml
```

### Using Local Ansible (Development)

```bash
# Run playbook
ansible-playbook -i hosts.runtime.yml playbooks/golden-image-rhel9.yml

# Test connectivity
ansible all -i hosts.runtime.yml -m ping

# Verbose output
ansible-playbook -i hosts.runtime.yml playbooks/golden-image-rhel9.yml -vvv

# Run specific role tags
ansible-playbook -i hosts.runtime.yml playbooks/golden-image-rhel9.yml --tags java
```

---

## 🔐 Security Architecture

### IAP Tunnel Configuration

All SSH access goes through **Identity-Aware Proxy (IAP)**:

```yaml
# hosts.runtime.yml configuration
ansible_ssh_common_args: >-
  -o ProxyCommand="gcloud compute start-iap-tunnel VM_NAME 22 
  --listen-on-stdin --project=PROJECT_ID --zone=ZONE
  --impersonate-service-account=SERVICE_ACCOUNT_EMAIL
  --verbosity=warning"
```

**Security Benefits:**
- ✅ No external IPs on VMs
- ✅ All connections authenticated via Google Identity
- ✅ Encrypted tunnels
- ✅ Centralized access control
- ✅ Full audit trail

### Cloud Build Configuration

Cloud Build dynamically creates inventory:

```yaml
# Dynamic inventory in cloudbuild.yaml
cat > hosts-cloudbuild.yml << 'EOF'
all:
  children:
    targets:
      hosts:
        ${_TARGET_VM}:
          ansible_host: ${_TARGET_VM}
          ansible_user: askcloudedge_gmail_com
          ansible_ssh_common_args: >-
            -o ProxyCommand="gcloud compute start-iap-tunnel ${_TARGET_VM} 22 
            --listen-on-stdin --project=${_PROJECT_ID} --zone=${_VM_ZONE}
            --verbosity=warning"
          ansible_ssh_private_key_file: /root/.ssh/ansible_key
          ansible_python_interpreter: auto_silent
EOF
```

### Secret Management

SSH keys are stored in **Secret Manager**:

```bash
# Secret name: ansible-ssh-private-key
# Access: Only service account can read
# Retrieved in Cloud Build: gcloud secrets versions access latest
```

### Network Security

- **No External IPs**: VMs are isolated from internet
- **Cloud NAT**: Provides outbound internet for package downloads
- **IAP Tunnel**: Inbound SSH access only via IAP
- **Service Account**: All automation uses service account authentication

---

## 📦 What Gets Installed

### Golden Image Components

Each playbook installs a complete runtime stack:

| Component | RHEL 7 | RHEL 8 | RHEL 9 |
|-----------|--------|--------|--------|
| **Java** | OpenJDK 11 | OpenJDK 11 | OpenJDK 17 LTS |
| **Node.js** | 18 LTS | 18 LTS | 18 LTS |
| **Python** | 3.6+ | 3.9+ | 3.9+ |
| **PostgreSQL Client** | Latest | 15 | 15 |

### Package Details

**Java SDK** (`install-java-sdk` role):
- OpenJDK Runtime + Development Kit
- `JAVA_HOME` environment variable configured
- Both `java` and `javac` validated

**Node.js** (`install-nodejs` role):
- Installed via NodeSource repository
- NPM included
- Major version validated

**Python** (`install-python` role):
- Python 3 runtime
- pip, setuptools, development headers
- Version validation

**PostgreSQL Client** (`install-database-cient` role):
- PostgreSQL client tools
- `psql` command-line utility
- Connection utilities

**Common Packages**:
- `curl`, `wget`, `git`, `unzip`, `tar`, `gzip`
- `jq`, `vim-enhanced`, `htop`, `tree`

---

## 📊 Monitoring & Troubleshooting

### View Workflow Execution

```bash
# List recent executions
gcloud workflows executions list ansible-cloudbuild-workflow \
  --location=us-central1 \
  --limit=10

# Describe specific execution
gcloud workflows executions describe <EXECUTION_ID> \
  --workflow=ansible-cloudbuild-workflow \
  --location=us-central1

# Get execution result
gcloud workflows executions describe <EXECUTION_ID> \
  --workflow=ansible-cloudbuild-workflow \
  --location=us-central1 \
  --format="value(result)"
```

### View Cloud Build Logs

```bash
# List recent builds
gcloud builds list --limit=10

# View build logs
gcloud builds log <BUILD_ID>

# Stream logs in real-time
gcloud builds log <BUILD_ID> --stream

# Describe build
gcloud builds describe <BUILD_ID>
```

### Test IAP Connectivity

```bash
# Test IAP tunnel manually
gcloud compute start-iap-tunnel ansible-rhel9-vm 22 \
  --local-host-port=localhost:2222 \
  --zone=us-central1-a

# In another terminal, test SSH
ssh -i ~/.ssh/ansible_test_key \
  -p 2222 \
  askcloudedge_gmail_com@localhost

# Test with Ansible
ansible all -i hosts.runtime.yml -m ping -vvv
```

### Common Issues & Solutions

#### 1. SSH Connection Failed via IAP

**Error:** `Failed to connect to the host via ssh`

**Solutions:**
```bash
# Check VM is running
gcloud compute instances describe ansible-rhel9-vm --zone=us-central1-a

# Verify IAP permissions
gcloud projects get-iam-policy $PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.role:roles/iap.tunnelResourceAccessor"

# Test IAP tunnel manually
gcloud compute start-iap-tunnel ansible-rhel9-vm 22 \
  --zone=us-central1-a \
  --local-host-port=localhost:2222
```

#### 2. Package Download Timeout

**Error:** `Failed to connect to rpm.nodesource.com port 443: Connection timed out`

**Solution:** Verify Cloud NAT is configured
```bash
# Check Cloud NAT exists
gcloud compute routers nats list --router=nat-router --region=us-central1

# If not configured, create it
gcloud compute routers create nat-router \
  --network=default \
  --region=us-central1

gcloud compute routers nats create nat-config \
  --router=nat-router \
  --region=us-central1 \
  --auto-allocate-nat-external-ips \
  --nat-all-subnet-ip-ranges
```

#### 3. Secret Not Found

**Error:** `Failed to access secret version`

**Solution:**
```bash
# Check secret exists
gcloud secrets describe ansible-ssh-private-key

# Grant access to service account
gcloud secrets add-iam-policy-binding ansible-ssh-private-key \
  --member="serviceAccount:ansible-automation@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
```

#### 4. Permission Denied Errors

**Error:** `Permission denied` or `403 Forbidden`

**Solution:** Verify all service account permissions
```bash
# Check current permissions
gcloud projects get-iam-policy $PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:ansible-automation@"

# Re-apply all permissions (see Step 3 in Setup Guide)
```

### Cloud Console Links

- **Workflows:** https://console.cloud.google.com/workflows?project=probable-cove-474504-p0
- **Cloud Build:** https://console.cloud.google.com/cloud-build?project=probable-cove-474504-p0
- **Secret Manager:** https://console.cloud.google.com/security/secret-manager?project=probable-cove-474504-p0
- **Compute Engine:** https://console.cloud.google.com/compute/instances?project=probable-cove-474504-p0
- **Cloud NAT:** https://console.cloud.google.com/net-services/nat/list?project=probable-cove-474504-p0

---

## 👥 Team Member Setup (For Shivani)

### One-Time Setup

```bash
# 1. Authenticate
gcloud auth login

# 2. Set project
gcloud config set project probable-cove-474504-p0

# That's it! No SSH keys or VM access needed.
```

### Deploy Anytime

```bash
# Run deployment
gcloud workflows run ansible-cloudbuild-workflow \
  --data='{"playbook":"golden-image-rhel9.yml"}' \
  --location=us-central1

# View execution
gcloud workflows executions list ansible-cloudbuild-workflow --location=us-central1
```

**Everything else is automated:**
- ✅ SSH keys from Secret Manager
- ✅ Service account authentication
- ✅ IAP tunnel automatically created
- ✅ Code pulled from GitHub
- ✅ Validation runs automatically

---

## 🔄 Making Changes

### Update Playbooks or Roles

1. **Make changes locally**
2. **Test with Cloud Build** (uses local files):
   ```bash
   gcloud builds submit . --config=cloudbuild.yaml
   ```
3. **Push to GitHub**:
   ```bash
   git add .
   git commit -m "Update playbook"
   git push origin master
   ```
4. **Deploy via workflow** (pulls from GitHub):
   ```bash
   gcloud workflows run ansible-cloudbuild-workflow \
     --data='{"playbook":"golden-image-rhel9.yml"}' \
     --location=us-central1
   ```

### Update Workflow

```bash
# Edit ansible-workflow-cloudbuild.yaml
vim ansible-workflow-cloudbuild.yaml

# Redeploy workflow
gcloud workflows deploy ansible-cloudbuild-workflow \
  --source=ansible-workflow-cloudbuild.yaml \
  --location=us-central1 \
  --service-account=ansible-automation@probable-cove-474504-p0.iam.gserviceaccount.com
```

### Update Cloud Build Config

```bash
# Edit cloudbuild.yaml
vim cloudbuild.yaml

# Test immediately
gcloud builds submit . --config=cloudbuild.yaml
```

---

## 🎯 Best Practices

### Development Workflow

```bash
# 1. Make changes locally
vim playbooks/golden-image-rhel9.yml

# 2. Test with local Ansible (fastest)
ansible-playbook -i hosts.runtime.yml playbooks/golden-image-rhel9.yml

# 3. Test with Cloud Build (validate IAP and Cloud Build config)
gcloud builds submit . --config=cloudbuild.yaml

# 4. Commit and push
git add .
git commit -m "Update playbook"
git push origin master

# 5. Deploy via workflow (production)
gcloud workflows run ansible-cloudbuild-workflow \
  --data='{"playbook":"golden-image-rhel9.yml"}' \
  --location=us-central1
```

### Security Best Practices

1. **Rotate SSH Keys Regularly**
   ```bash
   # Generate new key
   ssh-keygen -t ed25519 -f ~/.ssh/ansible_new_key
   
   # Update secret
   gcloud secrets versions add ansible-ssh-private-key \
     --data-file="${HOME}/.ssh/ansible_new_key"
   
   # Update VM metadata
   gcloud compute instances add-metadata ansible-rhel9-vm \
     --zone=us-central1-a \
     --metadata-from-file ssh-keys=<(echo "askcloudedge_gmail_com:$(cat ~/.ssh/ansible_new_key.pub)")
   ```

2. **Review Permissions Quarterly**
   ```bash
   # Audit service account permissions
   gcloud projects get-iam-policy probable-cove-474504-p0 \
     --flatten="bindings[].members" \
     --filter="bindings.members:ansible-automation@"
   ```

3. **Enable Audit Logging**
   ```bash
   # Audit logs are automatically enabled for IAP and Cloud Build
   # View IAP audit logs
   gcloud logging read "resource.type=gce_instance AND protoPayload.methodName=gcloud.compute.start-iap-tunnel"
   ```

---

## 📚 Quick Reference

### Essential Commands

```bash
# ========== WORKFLOW ==========
# Deploy with workflow (production)
gcloud workflows run ansible-cloudbuild-workflow \
  --data='{"playbook":"golden-image-rhel9.yml"}' \
  --location=us-central1

# List workflow executions
gcloud workflows executions list ansible-cloudbuild-workflow --location=us-central1

# ========== CLOUD BUILD ==========
# Deploy with Cloud Build (testing)
gcloud builds submit . --config=cloudbuild.yaml

# View build logs
gcloud builds log <BUILD_ID>

# List recent builds
gcloud builds list --limit=10

# ========== LOCAL ANSIBLE ==========
# Deploy with Ansible (development)
ansible-playbook -i hosts.runtime.yml playbooks/golden-image-rhel9.yml

# Test connectivity
ansible all -i hosts.runtime.yml -m ping

# Run with tags
ansible-playbook -i hosts.runtime.yml playbooks/golden-image-rhel9.yml --tags java,node

# ========== TROUBLESHOOTING ==========
# Check VM status
gcloud compute instances describe ansible-rhel9-vm --zone=us-central1-a

# Test IAP tunnel
gcloud compute start-iap-tunnel ansible-rhel9-vm 22 --zone=us-central1-a

# View secret
gcloud secrets describe ansible-ssh-private-key

# Check Cloud NAT
gcloud compute routers nats list --router=nat-router --region=us-central1
```

---

## 🏗 Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│  GITHUB REPOSITORY                                           │
│  https://github.com/anudishu/anisble-workflow-iap.git      │
│  - Ansible playbooks, roles, validation scripts             │
└────────────────┬─────────────────────────────────────────────┘
                 │ git clone (automatic)
                 ▼
┌─────────────────────────────────────────────────────────────┐
│  GOOGLE CLOUD WORKFLOW                                       │
│  - Orchestrates deployment                                   │
│  - Validates parameters                                      │
│  - Triggers Cloud Build                                      │
│  - Monitors execution                                        │
│  - Returns results with logs                                 │
└────────────────┬─────────────────────────────────────────────┘
                 │ trigger
                 ▼
┌─────────────────────────────────────────────────────────────┐
│  CLOUD BUILD (Service Account)                              │
│  ┌─────────────────────────────────────────────────────────┐│
│  │ 1. Clone code from GitHub                              ││
│  │ 2. Install Ansible + dependencies                      ││
│  │ 3. Retrieve SSH key from Secret Manager                ││
│  │ 4. Create dynamic inventory                            ││
│  │ 5. Establish IAP tunnel to VM                          ││
│  │ 6. Execute Ansible playbook                            ││
│  │ 7. Run validation scripts                              ││
│  │ 8. Report results                                       ││
│  └─────────────────────────────────────────────────────────┘│
└────────────────┬─────────────────────────────────────────────┘
                 │ IAP tunnel (encrypted)
                 ▼
┌─────────────────────────────────────────────────────────────┐
│  TARGET VM (No External IP)                                  │
│  - Receives Ansible deployment via IAP tunnel                │
│  - Installs: Java 17, Node.js 18, Python 3.9, PostgreSQL    │
│  - Runs validation                                           │
│  - Returns results                                           │
└─────────────────┬───────────────────────────────────────────┘
                  │ internet access via
                  ▼
         ┌──────────────────┐
         │  CLOUD NAT        │
         │  (outbound only)  │
         └──────────────────┘
```

---

## 📝 Configuration Files

### Workflow Configuration

**File:** `ansible-workflow-cloudbuild.yaml`

```yaml
# Default parameters
project_id: "probable-cove-474504-p0"
target_vm: "ansible-rhel9-vm"
vm_zone: "us-central1-a"
playbook: "golden-image-rhel9.yml"
git_repo: "https://github.com/anudishu/anisble-workflow-iap.git"
git_branch: "master"
```

### Cloud Build Configuration

**File:** `cloudbuild.yaml`

```yaml
# Default substitutions
_TARGET_VM: "ansible-rhel9-vm"
_VM_ZONE: "us-central1-a"
_PLAYBOOK: "golden-image-rhel9.yml"
```

### Inventory Configuration

**File:** `hosts.runtime.yml`

```yaml
all:
  children:
    targets:
      hosts:
        ansible-rhel9-vm:
          ansible_host: ansible-rhel9-vm
          ansible_user: askcloudedge_gmail_com
          ansible_ssh_common_args: >-
            -o ProxyCommand="gcloud compute start-iap-tunnel ansible-rhel9-vm 22 
            --listen-on-stdin --project=probable-cove-474504-p0 --zone=us-central1-a
            --impersonate-service-account=ansible-automation@probable-cove-474504-p0.iam.gserviceaccount.com
            --verbosity=warning"
          ansible_ssh_private_key_file: '/Users/Sumit_Kumar/.ssh/ansible_test_key'
          ansible_python_interpreter: auto_silent
```

---

## 🔗 Resources

- **GitHub Repository:** https://github.com/anudishu/anisble-workflow-iap.git
- **Google Cloud Workflows:** https://cloud.google.com/workflows/docs
- **Google Cloud Build:** https://cloud.google.com/build/docs
- **Identity-Aware Proxy:** https://cloud.google.com/iap/docs
- **Secret Manager:** https://cloud.google.com/secret-manager/docs
- **Cloud NAT:** https://cloud.google.com/nat/docs
- **Ansible Documentation:** https://docs.ansible.com

---

## ✅ Success Checklist

After deployment, verify:

- [ ] Workflow execution status = `SUCCEEDED`
- [ ] Cloud Build status = `SUCCESS`
- [ ] Java installed: `java -version` shows Java 17
- [ ] Node.js installed: `node --version` shows v18.x
- [ ] Python installed: `python3 --version` shows 3.9+
- [ ] PostgreSQL client: `psql --version` shows 15.x
- [ ] All validation scripts pass

---

**Project:** probable-cove-474504-p0  
**Repository:** https://github.com/anudishu/anisble-workflow-iap.git  
**Status:** ✅ Fully Operational  
**Last Updated:** November 13, 2025
