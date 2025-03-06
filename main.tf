provider "aws" {
  region                  = "us-east-1"
  access_key               = var.aws_access_key
  secret_key               = var.aws_secret_key
  token                     = var.aws_session_token
}

# VPC Module (same as before)
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name = "vault-demo-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]

  enable_nat_gateway   = true
  enable_dns_support   = true
  enable_dns_hostnames = true
}

# Vault Security Group
resource "aws_security_group" "vault" {
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 8200
    to_port     = 8200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Lock this down for real environments
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Vault EC2 Instance
resource "aws_instance" "vault" {
  ami                    = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2
  instance_type          = "t3.medium"
  subnet_id               = module.vpc.public_subnets[0]
  security_groups        = [aws_security_group.vault.name]

  user_data = templatefile("${path.module}/vault-install/user_data.tpl", {
    vault_version = "1.16.0+ent"
    license       = var.vault_license
    region        = "us-east-1"
  })

  tags = {
    Name = "vault-enterprise-server"
  }
}

# Output Vault URL
output "vault_address" {
  value = "http://${aws_instance.vault.public_ip}:8200"
}

# EKS Cluster (same as before)
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
