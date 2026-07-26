variable "aws_region" {
  description = "AWS region for the NIOS-X server"
  type        = string
  default     = "eu-central-1"
}

variable "name" {
  description = "Name of the NIOS-X server and its resources"
  type        = string
  default     = "niosx-aws-demo"

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

variable "ami_id" {
  description = "NIOS-X marketplace AMI ID (region specific)"
  type        = string
  default     = "ami-083f8f34b0e02be1a"

  validation {
    condition     = can(regex("^ami-[0-9a-f]{8,17}$", var.ami_id))
    error_message = "Must be a valid AMI ID, e.g. ami-083f8f34b0e02be1a."
  }
}

# Infoblox floor is 3 cores / 4 GB, and Xen-based instances are unsupported
# because they produce interface names with capital letters. c6a.xlarge is the
# cheapest current-generation Nitro type in eu-central-1 that clears the floor.
variable "instance_type" {
  description = "EC2 instance type - must be Nitro-based with at least 3 vCPU and 4 GB"
  type        = string
  default     = "c6a.xlarge"
}

variable "root_volume_size" {
  description = "Root volume size in GB (Infoblox documents 60 GB)"
  type        = number
  default     = 60

  validation {
    condition     = var.root_volume_size >= 60
    error_message = "NIOS-X requires at least 60 GB of storage."
  }
}

variable "vpc_cidr" {
  description = "CIDR of the demo VPC"
  type        = string
  default     = "10.90.0.0/24"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "Must be a valid IPv4 CIDR."
  }
}

variable "dns_client_cidr" {
  description = "CIDR allowed to query DNS on the server. Defaults to the VPC only."
  type        = string
  default     = "10.90.0.0/24"
}
