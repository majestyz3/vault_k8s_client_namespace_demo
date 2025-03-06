# VPC Module
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

# Security Group for Vault
resource "aws_security_group" "vault" {
  vpc_id = module.vpc.vpc_id

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
}

# EC2 Instance for Vault
resource "aws_instance" "vault" {
  ami                    = "ami-0c55b159cbfafe1f0"
  instance_type          = "t3.medium"
  subnet_id              = module.vpc.public_subnets[0]
  security_groups        = [aws_security_group.vault.name]
  key_name               = "vault-demo-key"

  user_data = templatefile("${path.module}/vault-install/user_data.tpl", {
    vault_version = "1.16.0+ent"
    region        = "us-east-1"
})


  provisioner "file" {
    source      = "${path.module}/vault.hclic"
    destination = "/etc/vault/vault.hclic"
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file(var.ssh_private_key)
  }

  tags = {
    Name = "vault-enterprise-server"
  }
}

# Output Vault Address
output "vault_address" {
  value = "http://${aws_instance.vault.public_ip}:8200"
}

# EKS Cluster
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
