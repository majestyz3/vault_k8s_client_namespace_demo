# Vault Kubernetes Client Namespace Demo

This repository contains Terraform configurations and scripts for deploying a **Highly Available HashiCorp Vault** setup with **Disaster Recovery (DR)** on AWS. The setup includes:

✅ **Primary Vault** on EC2  
✅ **Disaster Recovery (DR) Vault** on EC2  
✅ **EKS Cluster** for Kubernetes workloads  
✅ **AWS KMS for Vault Auto-Unseal**  
✅ **Automated Deployment with `all_in_one_deploy.sh`**  

---

## **📂 Folder Structure**
```
repo-root/
│── ansible-configure/        # Ansible configurations (if used)
│── configure/                # Additional configurations
│── infra/                    # Infrastructure-as-Code (Terraform)
│   ├── .terraform/           # Terraform local state directory
│   ├── vault-install/        # Vault installation scripts
│   │   ├── install_vault.sh              # Install script for Vault
│   │   ├── user_data_primary.tpl         # User data for Primary Vault
│   │   ├── user_data_dr.tpl              # User data for DR Vault
│   │   ├── vault-config-primary.hcl      # Config for Primary Vault
│   │   ├── vault-config-dr.hcl           # Config for DR Vault
│   │   ├── vault.hclic                   # Vault Enterprise License
│   ├── main.tf               # Terraform main configuration
│   ├── outputs.tf            # Terraform outputs
│   ├── providers.tf          # Terraform provider configurations
│   ├── variables.tf          # Terraform variables
│── all_in_one_deploy.sh      # End-to-end deployment script
│── deployment-outputs.txt    # Captured Terraform outputs
│── vault-demo-key.pem        # SSH Private Key (ensure this is NOT shared)
│── README.md                 # This file
│── .gitignore                # Git ignore for sensitive files
```

---

## **🚀 Deployment Instructions**

### **1️⃣ Install Prerequisites**
Make sure you have:
- **Terraform (>=1.3)**
- **AWS CLI**
- **Doormat CLI** (For HashiCorp internal AWS authentication)
- **jq** (For JSON parsing)
- **Bash**

### **2️⃣ Retrieve AWS Credentials**
Run:
```bash
doormat aws export --account aws_majid.zarkesh_test
```

### **3️⃣ Deploy Infrastructure**
Run:
```bash
./all_in_one_deploy.sh
```

This script will:
✅ **Initialize and apply Terraform**  
✅ **Capture output variables**  
✅ **Upload Vault configurations**  
✅ **Install Vault on EC2 instances**  
✅ **Initialize and unseal Vault**  

### **4️⃣ Access Vault UI**
- **Primary Vault:** `http://<vault_public_ip>:8200`
- **DR Vault:** `http://<vault_dr_public_ip>:8200`

Check the `deployment-outputs.txt` file for credentials.

---

## **🛠 Maintenance & Debugging**
To manually SSH into Vault instances:
```bash
ssh -i vault-demo-key.pem ec2-user@<vault_public_ip>
```

To check Vault logs:
```bash
sudo journalctl -u vault --no-pager
```

To check Terraform outputs:
```bash
terraform output
```

---

## **📌 Notes**
- The **use-case-tf** folder is a separate project and not relevant to this repo.
- The DR Vault is automatically configured to replicate secrets from the Primary Vault.
- **Security Reminder**: Make sure to keep your Vault license and unseal keys secure.

---

## **📜 License**
This project is licensed under the MIT License.

---

### **📧 Contact**
For any questions, feel free to reach out to **Majid Zarkesh**.
