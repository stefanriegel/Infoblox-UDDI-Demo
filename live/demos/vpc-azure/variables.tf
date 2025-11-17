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

variable "vnet_name" {
  description = "Azure VNet name"
  type        = string

  validation {
    condition     = length(var.vnet_name) > 0 && length(var.vnet_name) <= 64
    error_message = "VNet name must be between 1 and 64 characters."
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

variable "azure_location" {
  description = "Azure location for VNet"
  type        = string
}

variable "azure_block_id" {
  description = "UDDI Address Block ID for Azure (10.44.0.0/16)"
  type        = string
}

variable "ipam_space_id" {
  description = "UDDI IPAM Space ID"
  type        = string
}

  validation {
    condition     = contains(["westeurope", "eastus", "westus2", "southeastasia"], var.azure_location)
    error_message = "Azure location must be one of: westeurope, eastus, westus2, southeastasia."
  }
}
