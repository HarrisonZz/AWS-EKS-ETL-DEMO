variable "project_name" {
  type    = string
  default = "cloud-native-etl"
}

variable "env" {
  type    = string
  default = "dev"
}

variable "aws_region" {
  type    = string
  default = "ap-northeast-1"
}

variable "ingest_api_user" {
  type    = string
  default = "ingest-user"
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name; also used for subnet discovery tags"
}

variable "vpc_name" {
  type        = string
  description = "VPC name prefix"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block, e.g. 10.0.0.0/16"
}

variable "azs" {
  type        = list(string)
  description = "AZ list for HA, e.g. [\"ap-northeast-1a\", \"ap-northeast-1c\"]"
  validation {
    condition     = length(var.azs) >= 2
    error_message = "HA requires at least 2 AZs."
  }
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public subnet CIDRs; length must equal azs length"
  validation {
    condition     = length(var.public_subnet_cidrs) == length(var.azs)
    error_message = "public_subnet_cidrs length must equal azs length."
  }
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private subnet CIDRs; length must equal azs length"
  validation {
    condition     = length(var.private_subnet_cidrs) == length(var.azs)
    error_message = "private_subnet_cidrs length must equal azs length."
  }
}

variable "cluster_tag_mode" {
  type        = string
  default     = "owned"
  description = "Subnet cluster ownership tag: shared|owned"
  validation {
    condition     = contains(["shared", "owned"], var.cluster_tag_mode)
    error_message = "cluster_tag_mode must be 'shared' or 'owned'."
  }
}

variable "enable_nat_gateway" {
  type        = bool
  default     = true
  description = "Enable NAT gateways for private subnets"
}

variable "one_nat_gateway_per_az" {
  type        = bool
  default     = true
  description = "HA best practice: one NAT gateway per AZ"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Common tags applied to resources"
}
