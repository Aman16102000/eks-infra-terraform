data "aws_ssm_parameter" "eksami-prod" {
  name = format("/aws/service/eks/optimized-ami/%s/amazon-linux-2/recommended/image_id", var.cluster_version)
}
data "aws_eks_cluster" "eks" {
  name = var.aws_cluster_name
}


# Generate an SSH key pair
resource "tls_private_key" "ssh_key_beta" {
  algorithm = "RSA"
  rsa_bits  = 2048

}

# Save the private key locally
resource "local_file" "private_key_file_beta" {
  filename = "${path.module}/id_rsa"
  content  = tls_private_key.ssh_key_beta.private_key_pem
  file_permission = "0600" # Restrict permissions
  depends_on = [ aws_iam_role.beta_node_group_role,
                 aws_iam_role_policy_attachment.AmazonEKS_beta_CNI_Policy,
                 aws_iam_role_policy_attachment.eks_beta_registry,
                 aws_iam_role_policy_attachment.eks_beta_worker_node ]

}

# Save the public key locally
resource "local_file" "public_key_file" {
  filename = "${path.module}/id_rsa.pub"
  content  = tls_private_key.ssh_key_beta.public_key_openssh
    depends_on = [ aws_iam_role.beta_node_group_role,
                 aws_iam_role_policy_attachment.AmazonEKS_beta_CNI_Policy,
                 aws_iam_role_policy_attachment.eks_beta_registry,
                 aws_iam_role_policy_attachment.eks_beta_worker_node ]

}

# Upload the public key to AWS as an AWS Key Pair
resource "aws_key_pair" "project-name-eks-ssh_key_pair_beta" {
  key_name   = "project-name-eks-ssh_key_pair_beta" # Replace with your desired key pair name
  public_key = tls_private_key.ssh_key_beta.public_key_openssh

    depends_on = [ aws_iam_role.beta_node_group_role,
                 aws_iam_role_policy_attachment.AmazonEKS_beta_CNI_Policy,
                 aws_iam_role_policy_attachment.eks_beta_registry,
                 aws_iam_role_policy_attachment.eks_beta_worker_node ]

}

# Output the private key (optional, sensitive)
output "private_key" {
  value     = tls_private_key.ssh_key_beta.private_key_pem
  sensitive = true
}

# Output the public key
output "public_key" {
  value = tls_private_key.ssh_key_beta.public_key_openssh
}

# Output the AWS Key Pair name
output "aws_key_pair_name" {
  value = aws_key_pair.project-name-eks-ssh_key_pair_beta.key_name
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


resource "aws_launch_template" "launch_template_project-name-eks-beta" {
  # instance_type          = "t2.micro"
  key_name               = aws_key_pair.project-name-eks-ssh_key_pair_beta.key_name
  name                   = format("eks-Net-beta-%s", var.aws_cluster_name)
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
  depends_on = [ aws_key_pair.project-name-eks-ssh_key_pair_beta,
                  ]
}

# Spot Node Groups (1 per AZ)
resource "aws_eks_node_group" "spot_group_beta_a" {
  cluster_name    = var.aws_cluster_name
  node_group_name = "spot-group-beta-us-west-2a"
  node_role_arn   = aws_iam_role.beta_node_group_role.arn
  subnet_ids      = [var.public_subnet_ids[0]]
  launch_template {
    name = aws_launch_template.launch_template_project-name-eks-beta.name
    version = aws_launch_template.launch_template_project-name-eks-beta.latest_version
  }

  scaling_config {
    desired_size = 1
    max_size     = 5
    min_size     = 1
  }

  instance_types = ["t3.large", "t3.xlarge"]
  capacity_type  = "SPOT"

  labels = {
    capacityType = "SPOT"
  }

depends_on = [ aws_iam_role.beta_node_group_role,
                 aws_iam_role_policy_attachment.AmazonEKS_beta_CNI_Policy,
                 aws_iam_role_policy_attachment.eks_beta_registry,
                 aws_iam_role_policy_attachment.eks_beta_worker_node,
                 aws_launch_template.launch_template_project-name-eks-beta ]

}



#################################################################################33


resource "aws_eks_node_group" "spot_group_beta_b" {
    
  cluster_name    = var.aws_cluster_name
  node_group_name = "spot-group-beta-us-west-2b"
  node_role_arn   = aws_iam_role.beta_node_group_role.arn
  subnet_ids      = [var.public_subnet_ids[1]] # AZ us-west-2b
    launch_template {
    name = aws_launch_template.launch_template_project-name-eks-beta.name
    version = aws_launch_template.launch_template_project-name-eks-beta.latest_version
  }


  scaling_config {
    desired_size = 1
    max_size     = 5
    min_size     = 1
  }
  

  instance_types = ["t3.large", "t3.xlarge"]
  capacity_type  = "SPOT"

  labels = {
    capacityType = "SPOT"
  }
  

   depends_on = [ aws_iam_role.beta_node_group_role,
                 aws_iam_role_policy_attachment.AmazonEKS_beta_CNI_Policy,
                 aws_iam_role_policy_attachment.eks_beta_registry,
                 aws_iam_role_policy_attachment.eks_beta_worker_node,
                 aws_launch_template.launch_template_project-name-eks-beta ]
} 



resource "aws_iam_role" "beta_node_group_role" {
  name = "eks-beta-node-group-role"

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

resource "aws_iam_role_policy_attachment" "eks_beta_worker_node" {
  role       = aws_iam_role.beta_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_beta_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.beta_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "eks_beta_registry" {
  role       = aws_iam_role.beta_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy" "eks_beta_policyEBS" {
  name = "eks_beta_policyEBS"
  policy = jsonencode(
    {
      Statement = [
        {
          Action = [
            "ec2:AttachVolume",
            "ec2:CreateSnapshot",
            "ec2:CreateTags",
            "ec2:CreateVolume",
            "ec2:DeleteSnapshot",
            "ec2:DeleteTags",
            "ec2:DeleteVolume",
            "ec2:DescribeAvailabilityZones",
            "ec2:DescribeInstances",
            "ec2:DescribeSnapshots",
            "ec2:DescribeTags",
            "ec2:DescribeVolumes",
            "ec2:DescribeVolumesModifications",
            "ec2:DetachVolume",
            "ec2:ModifyVolume",
          ]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
      Version = "2012-10-17"
    }
  )
  role = aws_iam_role.beta_node_group_role.name
}



resource "aws_iam_role_policy_attachment" "storage" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.beta_node_group_role.name
}