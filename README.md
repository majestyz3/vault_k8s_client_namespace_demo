# Vault Enterprise Demo on AWS (Terraform)

This repo provisions a **Vault Enterprise Cluster on AWS** using Terraform and demonstrates how to:

✅ Deploy Vault on EC2 with an S3 backend  
✅ Automatically initialize & unseal Vault  
✅ Set up Kubernetes authentication for EKS  
✅ Create pre-linked entities and aliases to **map multiple namespaces to a single logical service identity**  
✅ Fully automate cleanup for fresh demo environments

---

## 📦 Folder Structure

| File/Folder | Purpose |
|---|---|
| `main.tf` | Infra + Vault install |
| `vault-setup.tf` | Kubernetes auth, entities, aliases, and policies |
| `vault-config.tpl` | Vault config file template (S3 backend) |
| `user_data.tpl` | EC2 bootstrapping (Vault install & service creation) |
| `unseal.sh` | Automate Vault init + unseal |
| `cleanup.sh` | Wipe Vault config + AWS resources |
| `.gitignore` | Protects sensitive files |
| `README.md` | This file - documentation & demo guide |

---

## 🚀 Deployment Steps

### Pre-Reqs

- AWS account with permissions to provision EC2, S3, VPC, and IAM.
- Vault Enterprise license file (`vault.hclic`).

If you are using temporary AWS credentials, you need:
### Setup Environment Variables

```sh
export AWS_ACCESS_KEY_ID=<your-access-key>
export AWS_SECRET_ACCESS_KEY=<your-secret-key>
export AWS_SESSION_TOKEN=<your-session-token>
export VAULT_LICENSE_PATH=./vault.hclic
