# ------------------------------------------------------------------------------
# Lookup Latest Amazon Linux 2 AMI ✅ FIXED: Declared data source
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
# Security Group for Vault Instance
# ------------------------------------------------------------------------------
resource "aws_security_group" "vault" {
  name   = "vault-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow SSH from anywhere (less secure)
  }

  ingress {
    from_port   = 8200
    to_port     = 8200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow Vault UI/API access
  }

  ingress {
    from_port   = 8201
    to_port     = 8201
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow Vault cluster communication
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
# ------------------------------------------------------------------------------
# Fetch AWS Account ID
# ------------------------------------------------------------------------------
data "aws_caller_identity" "current" {}

# ------------------------------------------------------------------------------
# IAM Role & Permissions for Vault Instance
# ------------------------------------------------------------------------------
resource "aws_iam_role" "vault_instance_role" {
  name = "vault-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name    = "Vault Instance Role"
    Project = "Vault K8S Client Namespace Demo"
  }
}

# ------------------------------------------------------------------------------
# IAM Policy for Vault KMS Auto-Unseal
# ------------------------------------------------------------------------------
resource "aws_kms_key" "vault_auto_unseal" {
  description             = "KMS key for Vault auto-unseal"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "vault-kms-key-policy"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { "AWS": "*" }
        Action    = ["kms:*"]
        Resource  = "*"
      }
    ]
  })

  tags = {
    Name    = "vault-auto-unseal"
    Project = "Vault K8S Client Namespace Demo"
  }
}



# ✅ Lookup the KMS key ARN *after* creation (prevents self-reference issues)
data "aws_kms_key" "vault_auto_unseal" {
  key_id = aws_kms_key.vault_auto_unseal.id
}

resource "aws_iam_policy" "vault_kms_policy" {
  name        = "VaultKMSPolicy"
  description = "IAM policy to allow Vault to use KMS for auto-unseal"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Resource = aws_kms_key.vault_auto_unseal.arn
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "vault_kms_policy_attachment" {
  policy_arn = aws_iam_policy.vault_kms_policy.arn
  role       = aws_iam_role.vault_instance_role.name
}

resource "aws_iam_instance_profile" "vault_instance_profile" {
  name = "vault-instance-profile"
  role = aws_iam_role.vault_instance_role.name
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

  iam_instance_profile = aws_iam_instance_profile.vault_instance_profile.name

  user_data = templatefile("${path.module}/vault-install/user_data.tpl", {
    VAULT_VERSION  = "1.19.0+ent"
    AWS_REGION     = var.aws_region
    VAULT_LICENSE  = var.vault_license
    KMS_KEY_ID     = aws_kms_key.vault_auto_unseal.arn
  })

  tags = {
    Name        = "vault-demo-instance"
    Project     = "Vault K8S Client Namespace Demo"
    Environment = "Demo"
    Owner       = "Majid Zarkesh"
  }
}

# ------------------------------------------------------------------------------
# Elastic IP for Vault  
# ------------------------------------------------------------------------------
resource "aws_eip" "vault" {
  instance = aws_instance.vault.id
  domain   = "vpc"

  tags = {
    Name    = "zarkesh-vault-demo-eip"
    Project = "Vault K8S Client Namespace Demo"
  }
}

# ------------------------------------------------------------------------------
# Generate Vault Configuration File
# ------------------------------------------------------------------------------
resource "local_file" "vault_config" {
  content  = templatefile("${path.module}/vault-install/vault-config.tpl", {
    PRIVATE_IP  = aws_instance.vault.private_ip
    KMS_KEY_ID  = aws_kms_key.vault_auto_unseal.arn
  })
  filename = "${path.module}/infra/vault-install/vault-config.hcl"
}

# ------------------------------------------------------------------------------
# EKS 
# ------------------------------------------------------------------------------
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "vault-demo-cluster"
  cluster_version = "1.28"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    default = {
      desired_size  = 2
      max_size      = 3
      min_size      = 1
      instance_types = ["t3.medium"]
    }
  }
}