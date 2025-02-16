variable "public_subnets" {
    type = list(string)

}

variable "private_subnets" {
    type = list(string)
}

variable "vpc_cidr_block" {
    type = string
}

variable "location" {
    type = string
}
variable "environment" {
    type = string
}

variable "aws_cluster_name"{
    type = string
}
variable "desired_size" {
    type = number
    default = 2
}