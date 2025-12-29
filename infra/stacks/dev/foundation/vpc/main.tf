terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

locals {
  name = "${var.project_name}-${var.env}"
  tags = merge(
    {
      Project   = var.project_name
      Env       = var.env
      ManagedBy = "terraform"
    },
    var.extra_tags
  )
}

module "vpc" {
  source = "../../../modules/vpc"

  name                 = local.name
  cidr                 = var.vpc_cidr
  azs                  = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs

  cluster_name     = var.cluster_name
  cluster_tag_mode = var.cluster_tag_mode

  enable_nat_gateway     = var.enable_nat_gateway
  one_nat_gateway_per_az = var.one_nat_gateway_per_az

  tags = local.tags
}
