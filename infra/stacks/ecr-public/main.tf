terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  alias  = "ecr_public"
  region = "us-east-1"
}

module "etl_demo_ecr_public" {
  source          = "../../modules/ecr-public"
  repository_name = var.repository_name
  description     = var.description
}
