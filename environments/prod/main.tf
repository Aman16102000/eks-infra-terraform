data "aws_ssm_parameter" "eksami-prod" {
  name = format("/aws/service/eks/optimized-ami/%s/amazon-linux-2/recommended/image_id", var.cluster_version)
}
data "aws_eks_cluster" "eks" {
  name = var.aws_cluster_name
}

# Generate an SSH key pair
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Save the private key locally
resource "local_file" "private_key_file" {
  filename = "${path.module}/id_rsa"
  content  = tls_private_key.ssh_key.private_key_pem
  file_permission = "0600" # Restrict permissions
}

# Save the public key locally
resource "local_file" "public_key_file" {
  filename = "${path.module}/id_rsa.pub"
  content  = tls_private_key.ssh_key.public_key_openssh
}

# Upload the public key to AWS as an AWS Key Pair
resource "aws_key_pair" "project-name-eks-ssh_key_pair" {
  key_name   = "project-name-eks-ssh_key_pair" # Replace with your desired key pair name
  public_key = tls_private_key.ssh_key.public_key_openssh
}

# Output the private key (optional, sensitive)
output "private_key" {
  value     = tls_private_key.ssh_key.private_key_pem
  sensitive = true
}

# Output the public key
output "public_key" {
  value = tls_private_key.ssh_key.public_key_openssh
}

# Output the AWS Key Pair name
output "aws_key_pair_name" {
  value = aws_key_pair.project-name-eks-ssh_key_pair.key_name
}

locals {
  eks-node-private-userdata = <<USERDATA
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="==MYBOUNDARY=="

--==MYBOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"

#!/bin/bash -xe
sudo /etc/eks/bootstrap.sh --apiserver-endpoint '${data.aws_eks_cluster.eks.endpoint}' --b64-cluster-ca '${data.aws_eks_cluster.eks.certificate_authority[0].data}' '${data.aws_eks_cluster.eks.name}'
echo "Running custom user data script" > /tmp/me.txt
yum install -y amazon-ssm-agent
echo "yum'd agent" >> /tmp/me.txt
yum update -y
systemctl enable amazon-ssm-agent && systemctl start amazon-ssm-agent
date >> /tmp/me.txt

--==MYBOUNDARY==--
USERDATA
}


resource "aws_launch_template" "launch_template_project-name-eks-prod" {
  # instance_type          = "t2.micro"
  key_name               = aws_key_pair.project-name-eks-ssh_key_pair.key_name
  name                   = format("eks-Net-%s", var.aws_cluster_name)
  tags                   = {}
  image_id               = data.aws_ssm_parameter.eksami-prod.value
  user_data              = base64encode(local.eks-node-private-userdata)
#   vpc_security_group_ids = [var.node_security_group_id]
  
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = format("eks-Net-%s", var.aws_cluster_name)
    }
  }
  lifecycle {
    create_before_destroy = true
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 30
      volume_type = "gp3"
      delete_on_termination = true
      encrypted             = true
    }
  }
}
# resource "aws_launch_template" "launch_template_project-name-eks-prod" {
#   key_name               = aws_key_pair.project-name-eks-ssh_key_pair.key_name
#   name                   = "${var.aws_cluster_name}_launch_template_prod"
# #   tags                   = {}
#   image_id               = "ami-04b706f6e63db19a8"
#   vpc_security_group_ids = [var.node_security_group_id]
# #   tag_specifications {
# #     resource_type = "instance"
# #     tags = {
# #       Name = format("%s-ng1", aws_eks_cluster.cluster.name)
# #     }
# #   }
#   lifecycle {
#     create_before_destroy = true
#   }

#   block_device_mappings {
#     device_name = "/dev/xvda"
#     ebs {
#       volume_size           = 30
#       volume_type = "gp3"
#       delete_on_termination = true
#       encrypted             = true
#     #   iops = 3000
#     }
#   }

#   depends_on = [aws_key_pair.project-name-eks-ssh_key_pair]
# }
# Spot Node Groups (1 per AZ)
resource "aws_eks_node_group" "spot_group_a" {
  cluster_name    = var.aws_cluster_name
  node_group_name = "spot-group-us-west-2a"
  node_role_arn   = aws_iam_role.node_group_role.arn
  subnet_ids      = [var.public_subnet_ids[0]]
  
  scaling_config {
    desired_size = 0
    max_size     = 5
    min_size     = 0
  }

  instance_types = ["t3.large", "t3.xlarge"]
  capacity_type  = "SPOT"

  labels = {
    capacityType = "SPOT"
  }

  depends_on = [ aws_iam_role.node_group_role,
                 aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
                 aws_iam_role_policy_attachment.eks_registry,
                 aws_iam_role_policy_attachment.eks_worker_node ]

}



#################################################################################33


resource "aws_eks_node_group" "spot_group_b" {
    
  cluster_name    = var.aws_cluster_name
  node_group_name = "spot-group-us-west-2b"
  node_role_arn   = aws_iam_role.node_group_role.arn
  subnet_ids      = [var.public_subnet_ids[1]] # AZ us-west-2b
    launch_template {
    name = aws_launch_template.launch_template_project-name-eks-prod.name
    version = aws_launch_template.launch_template_project-name-eks-prod.latest_version
  }


  scaling_config {
    desired_size = 0
    max_size     = 5
    min_size     = 0
  }
  

  instance_types = ["t3.large", "t3.xlarge"]
  capacity_type  = "SPOT"

  labels = {
    capacityType = "SPOT"
  }
    depends_on = [ aws_iam_role.node_group_role,
                 aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
                 aws_iam_role_policy_attachment.eks_registry,
                 aws_iam_role_policy_attachment.eks_worker_node,
                 aws_launch_template.launch_template_project-name-eks-prod ]
} 

# resource "aws_eks_node_group" "spot_group_c" {
#   cluster_name    = var.aws_cluster_name
#   node_group_name = "spot-group-us-west-2c"
#   node_role_arn   = aws_iam_role.node_group_role.arn
#   subnet_ids      = [var.public_subnet_ids[2]] # AZ us-west-2c
#     launch_template {
#     name = aws_launch_template.launch_template_project-name-eks-prod.name
#     version = aws_launch_template.launch_template_project-name-eks-prod.latest_version
#   }


#   scaling_config {
#     desired_size = 2
#     max_size     = 5
#     min_size     = 1
#   }

#   instance_types = ["t3.large", "t3.xlarge"]
#   capacity_type  = "SPOT"

#   labels = {
#     capacityType = "SPOT"
#   }
#       depends_on = [ aws_iam_role.node_group_role,
#                  aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
#                  aws_iam_role_policy_attachment.eks_registry,
#                  aws_iam_role_policy_attachment.eks_worker_node,
#                  aws_launch_template.launch_template_project-name-eks-prod ]

# }

# resource "aws_eks_node_group" "spot_group_d" {
#   cluster_name    = aws_eks_cluster.eks.name
#   node_group_name = "spot-group-d"
#   node_role_arn   = aws_iam_role.node_group_role.arn
#   subnet_ids      = [module.vpc.private_subnets[3]] # AZ us-west-2d

#   scaling_config {
#     desired_size = 2
#     max_size     = 5
#     min_size     = 1
#   }

#   instance_types = ["t3.large", "t3a.large", "t3d.large"]
#   capacity_type  = "SPOT"

#   labels = {
#     capacityType = "SPOT"
#   }

# }


resource "aws_iam_role" "node_group_role" {
  name = "eks-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node" {
  role       = aws_iam_role.node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group_role.name
}

resource "aws_iam_role_policy_attachment" "eks_registry" {
  role       = aws_iam_role.node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
