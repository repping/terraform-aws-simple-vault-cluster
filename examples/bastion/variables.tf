variable "region" {
  description = "The region for the provider to connect to."
  type        = string
  default     = "eu-west-1"

  validation {
    condition     = length(var.region) != 0
    error_message = "Region variable not set!"
  }
}

variable "ssh_allowed_from" {
  description = "CIDR block for SSH access to the bastion."
  type        = string
  default     = "0.0.0.0/0"

  validation {
    condition     = can(regex("^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(/([0-9]|[12][0-9]|3[0-2]))$", var.ssh_allowed_from))
    error_message = "Invalid cidr_block, pattern should be \"<ip>/<netmask>\". example: \"192.168.0.0/16\" "
  }
}