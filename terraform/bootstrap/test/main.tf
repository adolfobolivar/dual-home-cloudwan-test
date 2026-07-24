# terraform/bootstrap/test/main.tf
#
# Bootstraps the Terraform remote-state backend (S3 bucket + DynamoDB lock table) for
# the `test` AWS account (architecture.md §4.1). Deliberately uses local state, not the
# S3 backend it creates: every other module's remote backend depends on this bucket
# existing, so this module can't depend on it in turn. Apply this once, by hand,
# before running `terraform init` in terraform/environments/test/.

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  input = yamldecode(file("${path.module}/input.yaml"))
  # Shared with terraform/environments/test/ — same AWS account, one credentials file,
  # not a duplicate copy that could drift out of sync on rotation.
  secrets = yamldecode(file("${path.module}/../../environments/test/secrets.yaml"))
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

resource "aws_s3_bucket" "terraform_state" {
  bucket = local.input.state_bucket_name

  tags = {
    Name = local.input.state_bucket_name
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_lock" {
  name         = local.input.lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = local.input.lock_table_name
  }

  lifecycle {
    prevent_destroy = true
  }
}

output "state_bucket_name" {
  value = aws_s3_bucket.terraform_state.bucket
}

output "lock_table_name" {
  value = aws_dynamodb_table.terraform_lock.name
}
