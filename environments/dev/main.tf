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
  ami = "ami-0dba2cb6798deb6d8"  
  instance_type = "t3.medium"
  
  user_data = <<-EOF
  		#!/bin/bash
                sudo apt update -y
		sudo apt install openjdk-21-jdk -y
		sudo apt install maven -y
		sudo apt install git -y
		git clone -b security https://github.com/neerajbalodi/user-management-backend.git /home/ubuntu/user-management-backend 
		chown -R ubuntu:ubuntu /home/ubuntu/user-management-backend
              EOF

  tags = {
    Name = "usermgmtbe"
  }
}
