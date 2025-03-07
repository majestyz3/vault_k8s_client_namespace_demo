variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "ssh_private_key" {
  description = "Path to the private SSH key to connect to the EC2 instance"
  type        = string
  default     = "../vault-demo-key.pem"
}