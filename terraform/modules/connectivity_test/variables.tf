# terraform/modules/connectivity_test/variables.tf

variable "aws_region" {
  type        = string
  description = "AWS region, used in the CloudWatch Logs driver configuration."
}
