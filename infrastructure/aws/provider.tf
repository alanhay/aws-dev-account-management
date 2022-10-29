provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket         = "terraform-account-management-state"
    #key            = "terraform.tf.state"
    region         = "us-east-1"
    dynamodb_table = "terraform-account-management-locks"
    encrypt        = true
  }
}