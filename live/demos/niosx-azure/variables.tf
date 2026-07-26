variable "azure_location" {
  description = "Azure region. germanywestcentral is Frankfurt."
  type        = string
  default     = "germanywestcentral"
}

variable "name" {
  description = "Name of the NIOS-X server and its resources"
  type        = string
  default     = "niosx-azure-demo"

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{0,62}$", var.name))
    error_message = "Name must be 1-63 chars, alphanumeric or hyphen, and start with alphanumeric."
  }
}

variable "niosx_join_token" {
  description = "NIOS-X join token from the Infoblox Portal"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.niosx_join_token) > 0
    error_message = "Join token must not be empty."
  }
}

# Cheapest size in germanywestcentral that clears the 3 core / 4 GB floor AND
# has quota on this subscription. Basv2, DLSv5, DSv5 and DASv5 all sit at a
# limit of 0 cores there; BS, FSv2 and DSv3 have 10. F4s_v2 gives dedicated CPU
# for ~$1.50/mo more than the burstable B4ms.
variable "vm_size" {
  description = "Azure VM size - at least 3 vCPU and 4 GB, Gen2 capable, with regional quota"
  type        = string
  default     = "Standard_F4s_v2"
}

variable "image_version" {
  description = "Version of the infoblox-nios-x-vm marketplace image"
  type        = string
  default     = "4.1.10"
}

variable "os_disk_type" {
  description = "Managed disk type for the OS disk"
  type        = string
  default     = "StandardSSD_LRS"

  validation {
    condition     = contains(["Standard_LRS", "StandardSSD_LRS", "Premium_LRS"], var.os_disk_type)
    error_message = "Must be one of: Standard_LRS, StandardSSD_LRS, Premium_LRS."
  }
}

variable "vnet_cidr" {
  description = "CIDR of the demo VNet"
  type        = string
  default     = "10.91.0.0/24"

  validation {
    condition     = can(cidrhost(var.vnet_cidr, 0))
    error_message = "Must be a valid IPv4 CIDR."
  }
}
