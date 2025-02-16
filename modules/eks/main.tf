resource "aws_eks_cluster" "eks-project-name" {
  name = "eks-project-name"


  role_arn = aws_iam_role.cluster_iam_role.arn
  version  = "1.31"

  vpc_config {
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs = [
      "0.0.0.0/0",
    ]

    # security_group_ids = 

    subnet_ids = var.public_subnet_ids

  }

  # Ensure that IAM Role permissions are created before and deleted
  # after EKS Cluster handling. Otherwise, EKS will not be able to
  # properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role.cluster_iam_role,
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
    # aws_iam_role.node_group_role
    # aws_iam_role_policy_attachment.eks_worker_node,
    # aws_iam_role_policy_attachment.eks_cni,
    # aws_iam_role_policy_attachment.eks_registry
  ]
}

resource "aws_iam_role" "cluster_iam_role" {
  name = "cluster_iam_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster_iam_role.name
}


data "aws_eks_addon_version" "this" {
  addon_name         = "aws-ebs-csi-driver"
  kubernetes_version = aws_eks_cluster.eks-project-name.version
  most_recent        = true
}

resource "aws_eks_addon" "this" {

  cluster_name = aws_eks_cluster.eks-project-name.name
  addon_name   = "aws-ebs-csi-driver"

  addon_version               = data.aws_eks_addon_version.this.version
  configuration_values        = null
  preserve                    = true
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  service_account_role_arn    = null

}


