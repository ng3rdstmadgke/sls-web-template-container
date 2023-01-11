terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"

  backend "s3" {
    # TODO: 本番用に変更
    bucket = "tfstate-store-a5gnpkub"
    region = "ap-northeast-1"
    key = "search/crawler/prd/terraform.tfstate"
    encrypt = true
  }

}