terraform {
  backend "s3" {
    bucket         = "YOUR_TFSTATE_BUCKET"
    key            = "dev/vpc/terraform.tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "YOUR_TFSTATE_LOCK_TABLE"
    encrypt        = true
  }
}
