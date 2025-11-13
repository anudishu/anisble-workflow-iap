# Cloud Build Deployment Guide

## ✅ What We Accomplished

Successfully configured **automated Ansible deployments** using Google Cloud Build with:
- ✅ Service account authentication (`ansible-automation@probable-cove-474504-p0.iam.gserviceaccount.com`)
- ✅ SSH key stored securely in **Secret Manager** (`ansible-ssh-private-key`)
- ✅ IAP tunnel for secure VM access (no public IP needed)
- ✅ Cloud NAT for VM internet access (to download packages)
- ✅ Local file deployment (no Git repository required for testing)

## 🚀 Quick Start

### Deploy Ansible Playbook via Cloud Build

```bash
cd "Ansible-new-updated-iap copy"
gcloud builds submit . --config=cloudbuild.yaml --project=probable-cove-474504-p0
```

That's it! The build will:
1. Install Ansible in a Cloud Build container
2. Retrieve your SSH key from Secret Manager
3. Connect to the VM via IAP tunnel
4. Run the Ansible playbook (`golden-image-rhel9.yml`)
5. Execute validation scripts
6. Show results

## 📋 Configuration

### Current Settings

The `cloudbuild.yaml` is configured with:

```yaml
substitutions:
  _TARGET_VM: "ansible-rhel9-vm"
  _VM_ZONE: "us-central1-a"
  _PLAYBOOK: "golden-image-rhel9.yml"
```

### Deploy Different Playbook

```bash
gcloud builds submit . --config=cloudbuild.yaml \
  --substitutions=_PLAYBOOK=my-other-playbook.yml
```

### Deploy to Different VM

```bash
gcloud builds submit . --config=cloudbuild.yaml \
  --substitutions=_TARGET_VM=my-vm,_VM_ZONE=us-west1-a
```

### Deploy Multiple Changes

```bash
gcloud builds submit . --config=cloudbuild.yaml \
  --substitutions=_TARGET_VM=production-vm,_VM_ZONE=us-east1-b,_PLAYBOOK=production-playbook.yml
```

## 🔑 Authentication Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Cloud Build (runs as ansible-automation service account)   │
│                                                              │
│  1. Retrieves SSH key from Secret Manager                   │
│  2. Opens IAP tunnel to VM (no public IP needed)            │
│  3. Authenticates using your personal SSH key                │
│  4. Runs Ansible playbook                                    │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │  IAP Tunnel      │
                    │  (port 22)       │
                    └──────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │  ansible-rhel9-vm│
                    │  (no external IP)│
                    │                  │
                    │  Connected via   │
                    │  Cloud NAT for   │
                    │  internet access │
                    └──────────────────┘
```

## 🔐 Security Configuration

### Service Account Permissions

The `ansible-automation@probable-cove-474504-p0.iam.gserviceaccount.com` has:
- ✅ `roles/compute.instanceAdmin` - Manage VM instances
- ✅ `roles/iap.tunnelResourceAccessor` - Create IAP tunnels
- ✅ `roles/storage.objectAdmin` - Access Cloud Build artifacts
- ✅ `roles/logging.logWriter` - Write build logs
- ✅ `roles/secretmanager.secretAccessor` - Read SSH key from Secret Manager
- ✅ `roles/compute.osLogin` - SSH access to VMs

### SSH Key Security

- Your SSH private key (`/Users/Sumit_Kumar/.ssh/ansible_test_key`) is stored in **Secret Manager**
- Secret name: `ansible-ssh-private-key`
- Only the `ansible-automation` service account can access it
- Cloud Build retrieves it at runtime (never stored in code or logs)

### Network Security

- VM has **no external IP address** (private only)
- All access via **IAP tunnel** (encrypted, authenticated)
- **Cloud NAT** provides outbound internet (for package downloads)
- Inbound traffic completely blocked except via IAP

## 📊 Monitoring Builds

### View Build Progress

```bash
# Watch build in real-time
gcloud builds log <BUILD_ID> --stream

# View completed build
gcloud builds describe <BUILD_ID>

# List recent builds
gcloud builds list --limit=10
```

### Cloud Console

View builds at: https://console.cloud.google.com/cloud-build/builds?project=probable-cove-474504-p0

## 🛠 For Team Members (Shivani)

### Prerequisites

1. **Google Cloud SDK** installed
2. **Authenticated** to the project:
   ```bash
   gcloud auth login
   gcloud config set project probable-cove-474504-p0
   ```

3. **IAM Permissions** (ask project admin for):
   - `roles/cloudbuild.builds.editor` - Submit builds
   - `roles/viewer` - View resources

### Your First Build

```bash
# 1. Clone the repository
cd "Ansible-new-updated-iap copy"

# 2. Make any changes to playbooks or roles
# (edit files in playbooks/, roles/, etc.)

# 3. Submit the build
gcloud builds submit . --config=cloudbuild.yaml

# 4. Watch the build progress
# The command will stream logs automatically
```

**Note:** You don't need SSH keys or credentials - everything is handled by Secret Manager and the service account!

## 🐛 Troubleshooting

### Build Fails at SSH Connection

**Check:** Does the VM exist and is it running?
```bash
gcloud compute instances describe ansible-rhel9-vm \
  --zone=us-central1-a \
  --format="value(status)"
```

### Build Fails at Package Download

**Check:** Is Cloud NAT configured?
```bash
gcloud compute routers nats list --router=nat-router --region=us-central1
```

### Secret Access Denied

**Check:** Does service account have permission?
```bash
gcloud secrets get-iam-policy ansible-ssh-private-key
```

### IAP Tunnel Fails

**Check:** Does service account have IAP permission?
```bash
gcloud projects get-iam-policy probable-cove-474504-p0 \
  --flatten="bindings[].members" \
  --filter="bindings.members:ansible-automation@*"
```

## 📝 Build Configuration Reference

### Cloud Build Steps

The `cloudbuild.yaml` executes these steps:

1. **Verify VM** - Checks if target VM exists and is running
2. **Setup Ansible** - Installs Ansible and dependencies
3. **Retrieve SSH Key** - Gets key from Secret Manager
4. **Test Connectivity** - Verifies IAP tunnel and SSH access
5. **Run Playbook** - Executes the specified Ansible playbook
6. **Validate** - Runs validation scripts on the VM
7. **Report** - Shows deployment summary

### Build Timeout

Default: **30 minutes** (`1800s`)

To change:
```yaml
timeout: "3600s"  # 1 hour
```

### Build Machine Type

Default: Standard Cloud Build VM

For faster builds, use:
```yaml
options:
  machineType: 'E2_HIGHCPU_8'
```

## 🎯 Next Steps

### Option 1: Use Cloud Build (Current)
```bash
gcloud builds submit . --config=cloudbuild.yaml
```
- ✅ Best for CI/CD pipelines
- ✅ Best for team collaboration
- ✅ Best for automated deployments

### Option 2: Use Cloud Workflows
```bash
gcloud workflows run ansible-deployment-workflow \
  --data='{"playbook":"golden-image-rhel9.yml","target_vm":"ansible-rhel9-vm"}'
```
- ✅ Best for orchestration
- ✅ Best for complex workflows
- ✅ Best for scheduled deployments

### Option 3: Local Execution
```bash
ansible-playbook -i hosts.runtime.yml playbooks/golden-image-rhel9.yml
```
- ✅ Best for quick testing
- ✅ Best for development
- ✅ Best for debugging

## 📚 Related Documentation

- [QUICK-START.md](./QUICK-START.md) - Local deployment guide
- [WORKFLOW-SETUP-GUIDE.md](./WORKFLOW-SETUP-GUIDE.md) - Workflow orchestration
- [README.md](./README.md) - Complete project documentation

## 🆘 Support

If you encounter issues:

1. Check the build logs (automatically shown during build)
2. Review the troubleshooting section above
3. Check IAM permissions for the service account
4. Verify VM is accessible via IAP locally first

---

**Last Updated:** November 13, 2025  
**Status:** ✅ Fully Operational

