# terraform/environments/test/providers.tf
#
# Root module for the `test` environment. Provider/backend configuration; the
# network resources themselves are wired in via main.tf (the network module).

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {}
}

locals {
  input   = yamldecode(file("${path.module}/input.yaml"))
  secrets = yamldecode(file("${path.module}/secrets.yaml"))
}

provider "aws" {
  region     = local.input.aws_region
  access_key = local.secrets.aws_access_key_id
  secret_key = local.secrets.aws_secret_access_key
  token      = local.secrets.aws_session_token != "" ? local.secrets.aws_session_token : null

  default_tags {
    tags = {
      Environment = local.input.environment
      Project     = "dual-home-cloudwan-test"
      Owner       = "network-engineering"
      ManagedBy   = "Terraform"
    }
  }
}
