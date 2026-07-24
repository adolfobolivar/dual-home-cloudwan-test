# terraform/environments/test/backend.hcl
# Values must match terraform/bootstrap/test/input.yaml exactly.
bucket         = "dual-home-cloudwan-test-tfstate-20260723"
key            = "test/terraform.tfstate"
region         = "us-east-2"
dynamodb_table = "dual-home-cloudwan-test-tfstate-lock"
encrypt        = true
