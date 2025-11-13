# ⚡ **Ansible IAP Workflow - Quick Start Guide**

**🎯 Deploy Ansible playbooks to VMs via IAP in 3 steps**

---

## 🚀 **Step 1: One-Time Setup** (5 minutes)

```bash
# Clone the repository
git clone https://github.com/anudishu/ansible-updated-code-iap.git
cd ansible-updated-code-iap

# Deploy the workflow (automated script)
./deploy-workflow.sh YOUR-PROJECT-ID us-central1
```

**Replace:** `YOUR-PROJECT-ID` with your actual GCP project ID

---

## 🎯 **Step 2: Basic Usage**

```bash
# Deploy to a single VM
gcloud workflows run ansible-deployment-workflow \
  --location=us-central1 \
  --data='{
    "target_vm": "YOUR-VM-NAME",
    "project_id": "YOUR-PROJECT-ID",
    "vm_zone": "YOUR-VM-ZONE"
  }'
```

**Replace:**
- `YOUR-VM-NAME` → `web-server-01`
- `YOUR-PROJECT-ID` → `my-company-prod`
- `YOUR-VM-ZONE` → `us-central1-a`

---

## 🔧 **Step 3: Advanced Options**

### **🎛️ All Parameters:**
```bash
gcloud workflows run ansible-deployment-workflow \
  --location=us-central1 \
  --data='{
    "target_vm": "production-web-01",
    "project_id": "my-company-prod",
    "vm_zone": "us-central1-a", 
    "playbook": "golden-image-rhel9.yml",
    "ansible_user": "myuser_company_com",
    "service_account": "ansible-sa@my-project.iam.gserviceaccount.com",
    "git_branch": "main",
    "skip_validation": false
  }'
```

### **📋 Available Playbooks:**
- `golden-image-rhel9.yml` - Complete RHEL 9 setup (Java 17, Node.js, Python, PostgreSQL)
- `golden-image-rhel8.yml` - Complete RHEL 8 setup
- `golden-image-rhel7.yml` - Complete RHEL 7 setup

---

## 🔍 **Monitoring & Troubleshooting**

### **📊 Check Execution Status:**
```bash
# List recent executions
gcloud workflows executions list ansible-deployment-workflow \
  --location=us-central1 --limit=5

# Get execution details
gcloud workflows executions describe EXECUTION-ID \
  --workflow=ansible-deployment-workflow --location=us-central1
```

### **📋 View Build Logs:**
```bash
# List recent Cloud Build jobs
gcloud builds list --limit=5

# View specific build logs  
gcloud builds log BUILD-ID
```

---

## 🚨 **Common Issues & Quick Fixes**

### **❌ "VM not found"**
```bash
# Check VM exists and is running
gcloud compute instances list --filter="name:YOUR-VM-NAME"

# Start VM if stopped
gcloud compute instances start YOUR-VM-NAME --zone=YOUR-ZONE
```

### **❌ "IAP connection failed"**
```bash
# Test IAP tunnel manually
gcloud compute start-iap-tunnel YOUR-VM-NAME 22 \
  --local-host-port=localhost:2222 --zone=YOUR-ZONE

# Check firewall rules
gcloud compute firewall-rules list --filter="name:iap"
```

### **❌ "Permission denied"**
```bash
# Check your permissions
gcloud projects get-iam-policy YOUR-PROJECT-ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:user:$(gcloud auth list --filter=status:ACTIVE --format='value(account)')"
```

---

## 🎯 **Team Usage Examples**

### **🌐 Deploy to Multiple VMs:**
```bash
# Deploy to all web servers
for vm in web-01 web-02 web-03; do
  gcloud workflows run ansible-deployment-workflow \
    --location=us-central1 \
    --data="{\"target_vm\": \"$vm\", \"project_id\": \"YOUR-PROJECT\"}" &
done
wait
```

### **🔄 CI/CD Pipeline:**
```yaml
# .github/workflows/deploy.yml
- name: Deploy via Workflow
  run: |
    gcloud workflows run ansible-deployment-workflow \
      --location=us-central1 \
      --data='{
        "target_vm": "${{ github.event.inputs.vm_name }}",
        "project_id": "${{ secrets.GCP_PROJECT }}",
        "git_branch": "${{ github.ref_name }}"
      }'
```

---

## 📞 **Need Help?**

- **📖 Full Documentation:** `WORKFLOW-SETUP-GUIDE.md`
- **🔧 Setup Issues:** Check `deploy-workflow.sh` output
- **🎯 Custom Configuration:** Edit `ansible-deployment-workflow.yaml`
- **🚨 Troubleshooting:** Check Cloud Build logs in GCP Console

---

## 🎉 **Success! What Happens:**

1. **🔄 Workflow starts** → Creates Cloud Build job
2. **📥 Downloads** Ansible code from git repository  
3. **🔐 Connects** to your VM via IAP tunnel
4. **⚙️ Runs** Ansible playbook (Java, Node.js, Python, PostgreSQL)
5. **✅ Validates** installation with automated tests
6. **📊 Reports** results back to you

**Total Time: ~10-15 minutes per VM**

---

**🎯 You're ready to automate VM deployments with enterprise-grade security!** 🚀🔐


