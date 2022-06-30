variable "ami" {
  description = "Amazon machine image to use for the Bastion server"
  type        = string
  default     = ""

  validation {
    condition     = length(var.ami) != 0
    error_message = "Bastion AMI variable not set!"
  }
}
variable "vault_port" {
  description = "Port the Vault API socket will be listening on. Default is 8200"
  type        = number
  default     = 8200
}
variable "tags" {
  description = "Tags to be added to resource blocks."
  type        = map(string)
  default     = {}

  validation {
    condition     = var.tags["owner"] != ""
    error_message = "The owner tag is empty for the AWS resources. Please set the AWS owner tag in the root module."
  }
}
variable "ssh_pubkey" {
  description = "Public key of the bastion host"
  type        = string
  default     = ""
}
variable "instance_type" {
  description = "Instance type to use for the bastion host"
  type        = string
  default     = "t2.micro"

  validation {
    condition     = contains(["t2.micro", "t3.micro", "t3.small", "t3.medium", "t3.large"], var.instance_type)
    error_message = "Instance type must be one of: t2.micro t3.micro t3.small t3.medium t3.large"
  }
}
variable "region" {
  description = "region to deploy the cluster in, should be same as the VPC."
  type        = string
  default     = ""

  validation {
    condition     = length(var.region) != 0
    error_message = "Region variable not set!"
  }
}
variable "ssh_allowed_from" {
  description = "CIDR block to allow ssh from in the SSH security group"
  type        = string
  default     = "0.0.0.0/0"

  validation {
    condition     = can(regex("^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(/([0-9]|[12][0-9]|3[0-2]))$", var.ssh_allowed_from))
    error_message = "Invalid cidr_block, pattern should be \"<ip>/<netmask>\". example: \"192.168.0.0/16\" "
  }
}
variable "subnet" {
  description = "Subnet within the vpc to deploy the cluster in"
  type        = string
  default     = ""
}
variable "vpc" {
  description = "VPC to deploy the cluster in in"
  type        = string
  default     = ""
}