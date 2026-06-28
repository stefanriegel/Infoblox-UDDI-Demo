variable "bloxone_host" {
  description = "Infoblox UDDI API host (CSP URL)"
  type        = string
  default     = "https://csp.infoblox.com"
}

variable "bloxone_api_key" {
  description = "Infoblox UDDI API key (sensitive; provide via environment/secret)"
  type        = string
  sensitive   = true
}

variable "vpc_name" {
  description = "Name for the AWS VPC"
  type        = string
}

variable "subnet_size" {
  description = "Subnet size (CIDR prefix length, e.g. 24 for /24)"
  type        = number
  default     = 24
  validation {
    condition     = var.subnet_size >= 16 && var.subnet_size <= 28
    error_message = "Subnet size must be between /16 and /28."
  }
}

variable "aws_region" {
  description = "AWS Region to deploy VPC"
  type        = string
  default     = "eu-central-1"
}

variable "aws_block_id" {
  description = "AWS Federated Block ID (UUID only)"
  type        = string
}

variable "ipam_space_id" {
  description = "UDDI IPAM Space ID"
  type        = string
}
