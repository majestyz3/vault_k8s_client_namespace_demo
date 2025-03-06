terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# AWS VPC to host Vault
resource "aws_vpc" "vault_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "${var.vault_cluster_name}-vpc"
  }
}

# Subnet inside VPC
resource "aws_subnet" "vault_subnet" {
  vpc_id     = aws_vpc.vault_vpc.id
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "${var.vault_cluster_name}-subnet"
  }
}

# Security Group to allow Vault UI and SSH access (adjust for prod)
resource "aws_security_group" "vault_sg" {
  vpc_id = aws_vpc.vault_vpc.id

  ingress {
    from_port   = 8200  # Vault UI/API port
    to_port     = 8200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22    # SSH for debugging (optional)
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
    Name = "${var.vault_cluster_name}-sg"
  }
}

# S3 bucket to serve as Vault's storage backend
resource "aws_s3_bucket" "vault_backend" {
  bucket        = "${var.vault_cluster_name}-backend"
  force_destroy = true  # Allows destroying bucket during cleanup (for demo only)
}

# Vault server instance
resource "aws_instance" "vault_server" {
  ami             = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 (adjust as needed)
  instance_type   = "t3.medium"
  subnet_id       = aws_subnet.vault_subnet.id
  security_groups = [aws_security_group.vault_sg.name]

  user_data = templatefile("${path.module}/user_data.tpl", {
    vault_config = templatefile("${path.module}/vault-config.tpl", {
      storage_bucket = aws_s3_bucket.vault_backend.bucket
      region         = var.aws_region
      cluster_name   = var.vault_cluster_name
    })
  })

  tags = {
    Name = "${var.vault_cluster_name}-server"
  }
}

# After Vault instance is up, run unseal process
resource "null_resource" "init_and_unseal" {
  depends_on = [aws_instance.vault_server]

  provisioner "local-exec" {
    command = <<EOT
      chmod +x ./unseal.sh
      ./unseal.sh http://${aws_instance.vault_server.public_ip}:8200
    EOT
  }

  triggers = {
    instance_id = aws_instance.vault_server.id
  }
}
