variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type = string
}

variable "public_subnets" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnets" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type = string
}

variable "aws_cluster_name" {
  type = string
}