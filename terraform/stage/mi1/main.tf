terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"

  backend "s3" {
    bucket = "tfstate-store-a5gnpkub"
    region = "ap-northeast-1"
    key = "sls-web-template-container/mi1/terraform.tfstate"
    encrypt = true
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

variable "db_user" {}
variable "db_password" {}

output "db_host" {
  value = module.storage.db_host
}

output "db_port" {
  value = module.storage.db_port
}

locals {
  app_name = "sls-web-template-container"
  stage = "mi1"
  vpc_id = "vpc-0aa084a693ff324f4"
  subnets = ["subnet-015c06f1c967d4bfd", "subnet-0d43a2957b67e28bb"]
}

module "storage" {
  source = "../../module/storage"
  app_name = local.app_name
  stage = local.stage
  vpc_id = local.vpc_id
  subnets = local.subnets
  db_name = "app"
  db_user = var.db_user
  db_password = var.db_password
}