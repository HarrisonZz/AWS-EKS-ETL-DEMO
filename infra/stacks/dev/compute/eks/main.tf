terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "data_bucket" {
  source        = "../../modules/data_bucket"
  project_name  = var.project_name
  env           = var.env
  iam_user_name = var.ingest_api_user
}

module "vpc" {
  source = "../../modules/vpc"
  name   = var.vpc_name
  cidr   = var.vpc_cidr

  azs                  = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs

  cluster_name     = var.cluster_name
  cluster_tag_mode = var.cluster_tag_mode

  enable_nat_gateway     = var.enable_nat_gateway
  one_nat_gateway_per_az = var.one_nat_gateway_per_az

  tags = var.tags

}

module "eks" {

}


