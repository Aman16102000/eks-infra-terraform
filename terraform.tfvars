location= "us-west-2"
vpc_cidr_block = "10.0.0.0/16"
public_subnets = [
  "10.0.0.0/22",  # First public subnet
  "10.0.4.0/22",  # Second public subnet
  "10.0.8.0/22",  # Third public subnet
  "10.0.12.0/22"  # Fourth public subnet
]

private_subnets = [
  "10.0.16.0/22",  # First private subnet
  "10.0.20.0/22",  # Second private subnet
  "10.0.24.0/22",  # Third private subnet
  "10.0.28.0/22"   # Fourth private subnet
]
environment = "eks-project-name"
aws_cluster_name = "eks-project-name"