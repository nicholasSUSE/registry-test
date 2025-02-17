terraform {
  required_providers {
    # manage resources in AWS
    aws = {
      source  = "hashicorp/aws"
      version = "5.1.0"
    }
    # manage local filesystem resources (CRUD) files on the local machine that terraform is run
    local = {
      source  = "hashicorp/local"
      version = "2.4.0"
    }
    # Generate and manage TLS certificates and keys
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.4"
    }
    # Execute commands through SSH on EC2 instances
    ssh = {
      source  = "loafoe/ssh"
      version = "2.6.0"
    }
  }
}

provider "aws" {
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
  token      = var.aws_session_token
  region     = var.aws_region
}
