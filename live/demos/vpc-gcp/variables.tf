variable "bloxone_host" {
  description = "Infoblox BloxOne CSP URL"
  type        = string
  default     = "https://csp.infoblox.com"
}

variable "bloxone_api_key" {
  description = "Infoblox BloxOne API Key"
  type        = string
  sensitive   = true
}

variable "vpc_name" {
  description = "GCP VPC network name"
  type        = string

  validation {
    condition     = length(var.vpc_name) > 0 && length(var.vpc_name) <= 63
    error_message = "VPC name must be between 1 and 63 characters."
  }

  validation {
    condition     = can(regex("^[a-z][-a-z0-9]*$", var.vpc_name))
    error_message = "VPC name must start with lowercase letter and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "subnet_size" {
  description = "Subnet size (CIDR prefix length, e.g., 24 for /24)"
  type        = number

  validation {
    condition     = var.subnet_size >= 16 && var.subnet_size <= 28
    error_message = "Subnet size must be between 16 and 28."
  }
}

variable "gcp_region" {
  description = "GCP region"
  type        = string
  default     = "europe-west1"

  validation {
    condition     = contains(["europe-west1", "us-central1", "us-west1", "asia-southeast1"], var.gcp_region)
    error_message = "GCP region must be one of: europe-west1, us-central1, us-west1, asia-southeast1."
  }
}

variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string

  validation {
    condition     = length(var.gcp_project_id) > 0
    error_message = "GCP Project ID must not be empty."
  }
}

variable "gcp_block_id" {
  description = "UDDI Address Block ID for GCP (10.43.0.0/16)"
  type        = string
}

variable "ipam_space_id" {
  description = "UDDI IPAM Space ID"
  type        = string
}
