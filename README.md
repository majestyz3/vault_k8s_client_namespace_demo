Vault Kubernetes Client Namespace Demo

Overview
This project demonstrates how to deploy a HashiCorp Vault instance on AWS EC2 and an EKS cluster to showcase Kubernetes client namespace authentication with Vault. The project is split into two key phases:

Infrastructure Setup: This includes creating a VPC, EKS cluster, and Vault EC2 instance.
Vault Configuration: This handles enabling Kubernetes auth, configuring backends, and setting up roles and policies.

Directory Structure

vault_k8s_client_namespace_demo/
│-- infra/                   # Terraform code for infrastructure setup
│-- configure/                # Ansible code for Vault configuration
│-- vault-install/            # Contains Vault installation and configuration templates
│-- deployment-outputs.txt    # Captured outputs after deployment
│-- vault.hclic                # Vault Enterprise license file (gitignored)
│-- vault-demo-key.pem         # SSH private key for Vault instance (gitignored)
│-- all_in_one_deploy.sh      # Main deployment script
│-- README.md                  # This file
│-- .gitignore                  # Ensures sensitive files are not pushed to Git
Prerequisites
Terraform >= 1.3.0
AWS CLI installed & configured
Doormat CLI (if using Doormat for credentials)
Ansible installed (for configuration phase)
HashiCorp Vault binary (for local testing)
Deployment Process
Step 1 - AWS Credentials via Doormat (Recommended)
Start the Doormat Credential Server:


doormat cred-server
The all_in_one_deploy.sh script will automatically detect the running credential server and configure Terraform to pull credentials from it.

Step 2 - Run the All-In-One Deployment Script
This script handles everything:

bash
Copy
Edit
./all_in_one_deploy.sh
The script will:

Fetch credentials from Doormat
Run terraform init and terraform apply in the infra/ folder
Capture outputs (like public IP) into deployment-outputs.txt
Copy required files to the Vault EC2 instance (license, install script)
Install Vault, initialize it, and unseal it.
Important Outputs
After the script runs, deployment-outputs.txt will contain:

Vault Public IP
EKS Cluster Endpoint
EKS Cluster CA Cert
These will be needed for the configure phase.

Step 3 - Configure Vault (after deployment)
Navigate to configure/ and run the Ansible playbook:


cd configure
ansible-playbook configure-vault.yaml
This configures Kubernetes authentication in Vault.

Directory Details
infra/
Contains Terraform code for VPC, EKS, and EC2 instance.
terraform.tfvars defines variables (like region, key name).
Uses Doormat’s credential server if available.
configure/
Contains configure-vault.yaml to set up Kubernetes auth in Vault.
vault-install/
user_data.tpl: Cloud-init template for installing Vault on EC2.
vault-config.tpl: Basic Vault configuration file.
Using Without Doormat (Manual Credentials)
If you do NOT want to use Doormat and prefer to pass AWS credentials directly, modify:

1. terraform.tfvars
Set:


aws_access_key = "your-access-key"
aws_secret_key = "your-secret-key"
aws_session_token = "your-session-token" # Optional if using temporary credentials
2. providers.tf (in infra/)
Replace the AWS provider block with:


provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  token      = var.aws_session_token
}

Cleanup
To clean up all deployed resources:


cd infra
terraform destroy
Notes
The vault.hclic file should never be committed to git.
Ensure vault-demo-key.pem is also ignored via .gitignore.
Both files need to be available locally when running the script.
Example Environment File
Example terraform.tfvars:


aws_region = "us-east-1"
key_name   = "vault-demo-key"
ssh_private_key = "../vault-demo-key.pem"
