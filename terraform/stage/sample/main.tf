terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"

  backend "s3" {
    bucket = "xxxxxxxxxxxxxx"
    region = "ap-northeast-1"
    key = "sls-web-template-container/sample/terraform.tfstate"
    encrypt = true
  }
}