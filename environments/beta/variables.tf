variable "aws_cluster_name" {
  type = string
}
# variable "private_subnet_ids" {
#   type = list(string)
# }
variable "public_subnet_ids" {
  type = list(string)
}

variable "node_security_group_id" {
  type = string
}

variable "cluster_version" {
  type = string
}