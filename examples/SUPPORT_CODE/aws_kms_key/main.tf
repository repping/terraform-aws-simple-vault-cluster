variable "region" {
  description = "Region to deploy the AWS KMS key"
  default = "eu-west-1"
}

terraform {
  required_version = ">= 0.14.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = var.region
}

variable "tags" {
  description = "Tags so folks know who made this possibly long lasting/existing AWS KMS key. Best use terraform.tfvars so set this variable."
  type = map
  default = {
    owner = "owner unspecified"
  }
}

# Make a key for unsealing.
resource "aws_kms_key" "default" {
  # count       = var.aws_kms_key_id == "" ? 1 : 0
  description = "Temp dummy Vault unseal key"
  tags        = var.tags
}

resource "aws_kms_alias" "default" {
  name          = "alias/vault_unseal_dummy_user-supplied"
  target_key_id = aws_kms_key.default.key_id
}

output "aws_kms_key_id" {
  value = aws_kms_key.default.id
}