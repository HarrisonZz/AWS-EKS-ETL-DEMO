variable "aws_region" {
  type    = string
  default = "ap-northeast-1"
}

variable "project_name" {
  type    = string
  default = "cloud-native-etl"
}

variable "env" {
  type    = string
  default = "dev"
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name used for subnet tags"
}

variable "vpc_cidr" {
  type        = string
  description = "e.g. 10.0.0.0/16"
}

variable "azs" {
  type        = list(string)
  description = "At least 2 AZs for HA"
  validation {
    condition     = length(var.azs) >= 2
    error_message = "For HA, azs must have at least 2 AZs."
  }
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Must match azs length"
  validation {
    condition     = length(var.public_subnet_cidrs) == length(var.azs)
    error_message = "public_subnet_cidrs length must equal azs length."
  }
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Must match azs length"
  validation {
    condition     = length(var.private_subnet_cidrs) == length(var.azs)
    error_message = "private_subnet_cidrs length must equal azs length."
  }
}

variable "cluster_tag_mode" {
  type    = string
  default = "owned" # 一 VPC 一 EKS：owned 較乾淨
  validation {
    condition     = contains(["shared", "owned"], var.cluster_tag_mode)
    error_message = "cluster_tag_mode must be 'shared' or 'owned'."
  }
}

variable "enable_nat_gateway" {
  type    = bool
  default = true
}

variable "one_nat_gateway_per_az" {
  type    = bool
  default = true
}

variable "extra_tags" {
  type    = map(string)
  default = {}
}
