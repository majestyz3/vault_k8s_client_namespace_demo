terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# ------------------------------------------------------------------------------
# VPC Module - Creates a dedicated VPC for this demo
# ------------------------------------------------------------------------------
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name   = "vault-demo-vpc"
  cidr   = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]

  enable_nat_gateway   = true
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Project = "Vault K8S Client Namespace Demo"
  }
}

# ------------------------------------------------------------------------------
# EKS Module - Sets up the EKS Cluster and Node Group
# ------------------------------------------------------------------------------
module "eks" {
  source = "terraform-aws-modules/eks/aws"
  cluster_name    = "vault-demo-cluster"
  cluster_version = "1.28"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    default = {
      desired_size    = 2
      max_size        = 3
      min_size        = 1
      instance_types  = ["t3.medium"]

      tags = {
        Project = "Vault K8S Client Namespace Demo"
      }
    }
  }

  tags = {
    Project = "Vault K8S Client Namespace Demo"
  }
}

# ------------------------------------------------------------------------------
# Lookup Amazon Linux 2 AMI for Vault EC2 Instance
# ------------------------------------------------------------------------------
data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  owners = ["amazon"]
}

# ------------------------------------------------------------------------------
# Security Group for Vault EC2
# ------------------------------------------------------------------------------
resource "aws_security_group" "vault" {
  name        = "vault-sg"
  description = "Security group for Vault EC2 instance"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 8200
    to_port     = 8200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project = "Vault K8S Client Namespace Demo"
  }
}

# ------------------------------------------------------------------------------
# Vault EC2 Instance
# ------------------------------------------------------------------------------
resource "aws_instance" "vault" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.medium"
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids  = [aws_security_group.vault.id]
  key_name                = "vault-demo-key"

  tags = {
    Name    = "vault-demo-ec2"
    Project = "Vault K8S Client Namespace Demo"
  }

  user_data = templatefile("${path.module}/vault-install/user_data.tpl", {
    vault_version = "1.16.0+ent"
    region        = "us-east-1"
    vault_config  = file("${path.module}/vault-install/vault-config.tpl")
  })

  # ----------------------------------------------------------------------------
  # Copy Vault License to the instance (critical for Vault Enterprise)
  # ----------------------------------------------------------------------------
  provisioner "file" {
    source      = "${path.root}/vault.hclic"
    destination = "/etc/vault/vault.hclic"
  }

  # ----------------------------------------------------------------------------
  # SSH Connection Config for provisioners
  # ----------------------------------------------------------------------------
  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file(var.ssh_private_key)
  }

  # ----------------------------------------------------------------------------
  # Remote-Exec to Initialize Vault and Save Keys/Token (one-time only)
  # ----------------------------------------------------------------------------
  provisioner "remote-exec" {
    inline = [
      "if [ ! -f /etc/vault/.initialized ]; then",
      "  export VAULT_ADDR=http://127.0.0.1:8200",
      "  sleep 10",    # Let Vault start up fully
      "  vault operator init -format=json > /etc/vault/init.json",
      "  jq -r '.unseal_keys_b64[]' /etc/vault/init.json > /etc/vault/unseal-keys.txt",
      "  jq -r '.root_token' /etc/vault/init.json > /etc/vault/root-token.txt",
      "  touch /etc/vault/.initialized",
      "fi"
    ]
  }

  # ----------------------------------------------------------------------------
  # Local-Exec to Fetch the Keys/Token Back to Local Machine
  # ----------------------------------------------------------------------------
  provisioner "local-exec" {
    command = <<EOT
ssh -o StrictHostKeyChecking=no -i ${var.ssh_private_key} ec2-user@${self.public_ip} "cat /etc/vault/unseal-keys.txt" > ../unseal-keys.txt
ssh -o StrictHostKeyChecking=no -i ${var.ssh_private_key} ec2-user@${self.public_ip} "cat /etc/vault/root-token.txt" > ../root-token.txt
EOT
  }
}

