variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
}

variable "security_group_name" {
  description = "Name of the security group"
  type        = string
}

variable "ami" {
  description = "Amazon machine id"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}
