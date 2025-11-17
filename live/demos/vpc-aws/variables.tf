variable "bloxone_host" {
  description = "Infoblox UDDI API Host"
  type        = string
  default     = "https://csp.infoblox.com"
}

variable "bloxone_api_key" {
  description = "Infoblox UDDI API Key"
  type        = string
  sensitive   = true
}

variable "vpc_name" {
  description = "Name for the AWS VPC"
  type        = string
}

variable "subnet_size" {
  description = "Subnet size (CIDR notation, e.g., /16, /24)"
  type        = number
  validation {
    condition     = var.subnet_size >= 16 && var.subnet_size <= 28
    error_message = "Subnet size must be between /16 and /28"
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
  description = "IPAM Space ID"
  type        = string
}
