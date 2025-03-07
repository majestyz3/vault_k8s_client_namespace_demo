# ------------------------------------------------------------------------------
# VPC Module - Creates Network Infrastructure
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
}

# ------------------------------------------------------------------------------
# EKS Cluster - Kubernetes Cluster for Demo
# ------------------------------------------------------------------------------
module "eks" {
  source = "terraform-aws-modules/eks/aws"
  cluster_name    = "vault-demo-cluster"
  cluster_version = "1.28"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    default = {
      desired_size = 2
      max_size     = 3
      min_size     = 1
      instance_types = ["t3.medium"]
    }
  }
}


# ------------------------------------------------------------------------------
# Lookup Latest Amazon Linux 2 AMI
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
# Security Group for Vault Instance
# ------------------------------------------------------------------------------
resource "aws_security_group" "vault" {
  name        = "vault-sg"
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
}

# ------------------------------------------------------------------------------
# public ip for vault  
# ------------------------------------------------------------------------------
resource "aws_eip" "vault" {
  instance = aws_instance.vault.id
  domain   = "vpc"

  tags = {
    Name = "zarkesh-vault-demo-eip"
    Project = "Vault K8S Client Namespace Demo"
  }
}

# ------------------------------------------------------------------------------
# EC2 Instance for Vault Server
# ------------------------------------------------------------------------------
resource "aws_instance" "vault" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.medium"
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.vault.id]
  key_name               = "vault-demo-key"

  user_data = templatefile("${path.module}/vault-install/user_data.tpl", {
    VAULT_VERSION  = "1.19.0+ent"
    AWS_REGION     = var.aws_region
    VAULT_LICENSE  = var.vault_license
    KMS_KEY_ID     = aws_kms_key.vault_auto_unseal.key_id
  })

  tags = {
    Name        = "vault-demo-instance"
    Project     = "Vault K8S Client Namespace Demo"
    Environment = "Demo"
    Owner       = "Majid Zarkesh"
  }
}


# ------------------------------------------------------------------------------
# KMS Key for Vault Auto-Unseal
# ------------------------------------------------------------------------------
resource "aws_kms_key" "vault_auto_unseal" {
  description             = "KMS key for Vault auto-unseal (Vault Demo)"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name        = "vault-auto-unseal"
    Project     = "Vault K8S Client Namespace Demo"
    Environment = "Demo"
    Owner       = "Majid Zarkesh"
  }
}

resource "aws_kms_alias" "vault_auto_unseal" {
  name          = "alias/vault-auto-unseal"
  target_key_id = aws_kms_key.vault_auto_unseal.key_id
}