terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = "us-west-1"  # Change this if needed
}

resource "aws_instance" "usermgmtbe" {
  ami           = "ami-0290e60ec230db1e4"  # Amazon Linux 2 in us-east-1, update per your region
  instance_type = "t3.medium"

  tags = {
    Name = "usermgmtbe"
  }
}
