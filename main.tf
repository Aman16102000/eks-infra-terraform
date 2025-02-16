module "vpc" {
    source = "./modules/vpc"
    vpc_cidr_block= var.vpc_cidr_block
    public_subnets =  var.public_subnets 
    private_subnets =  var.private_subnets 
    environment = var.environment
    aws_cluster_name = var.aws_cluster_name
}

module "eks" {
    source = "./modules/eks"
    public_subnet_ids = module. vpc.public_subnet_ids
    vpc_id = module.vpc.vpc_id
}

module "eks_managed_node_group" {
  source = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"

  name            = "separate-eks-mng"
  cluster_name    = var.aws_cluster_name
  cluster_version = "1.31"

  subnet_ids = module.vpc.public_subnet_ids

  // The following variables are necessary if you decide to use the module outside of the parent EKS module context.
  // Without it, the security groups of the nodes are empty and thus won't join the cluster.
  cluster_primary_security_group_id = "sg-0fd5e4aa7c2be7175"
#   vpc_security_group_ids            = [module.eks.node_security_group_id]
// Get the below value from this aws eks describe-cluster --name eks-project-name --query "cluster.kubernetesNetworkConfig.serviceIpv4Cidr" --output text
  cluster_service_cidr = "172.20.0.0/16"


  min_size     = 1
  max_size     = 4
  desired_size = 1
  instance_types = ["t3.large"]
  capacity_type  = "SPOT"
}


module "node_group" {
    source = "./environments/prod"
    aws_cluster_name = var.aws_cluster_name
    # private_subnet_ids = module.vpc.private_subnet_ids
    public_subnet_ids = module.vpc.public_subnet_ids
    node_security_group_id = module.vpc.node_security_group
    cluster_version = "1.31"
}

module "beta_node_group" {
    source = "./environments/beta"
    aws_cluster_name = var.aws_cluster_name
    # private_subnet_ids = module.vpc.private_subnet_ids
    public_subnet_ids = module.vpc.public_subnet_ids
    node_security_group_id = module.vpc.node_security_group
    cluster_version = "1.31"
}