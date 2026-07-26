variable "proxmox_endpoint" {
  description = "Proxmox VE API endpoint"
  type        = string
  default     = "https://pve-fsn1-dc13.infra.blox42.rocks:8006/"
}

variable "proxmox_api_token" {
  description = "Proxmox API token in the form user@realm!tokenid=secret"
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^[^@]+@[^!]+![^=]+=.+$", var.proxmox_api_token))
    error_message = "Token must look like user@realm!tokenid=secret."
  }
}

variable "proxmox_insecure" {
  description = "Skip TLS verification (the cluster uses a self-signed certificate)"
  type        = bool
  default     = true
}

variable "proxmox_node" {
  description = "Target node for the clone. Empty string auto-picks the first online node."
  type        = string
  default     = ""
}

variable "template_vm_id" {
  description = "VMID of the NIOS-X template to clone"
  type        = number
  default     = 1061
}

variable "template_node" {
  description = "Node the NIOS-X template lives on"
  type        = string
  default     = "pve-fsn1-dc17"
}

variable "vm_name" {
  description = "Name of the cloned NIOS-X server"
  type        = string
  default     = "niosx-demo"

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{0,62}$", var.vm_name))
    error_message = "VM name must be 1-63 chars, alphanumeric or hyphen, and start with alphanumeric."
  }
}

variable "vm_cores" {
  description = "vCPU cores for the cloned VM"
  type        = number
  default     = 4

  validation {
    condition     = var.vm_cores >= 2 && var.vm_cores <= 32
    error_message = "Cores must be between 2 and 32."
  }
}

variable "vm_memory" {
  description = "Memory for the cloned VM in MB"
  type        = number
  default     = 8192

  validation {
    condition     = var.vm_memory >= 4096 && var.vm_memory <= 65536
    error_message = "Memory must be between 4096 and 65536 MB."
  }
}

variable "network_bridge" {
  description = "Bridge / SDN vnet to attach the NIOS-X server to"
  type        = string
  default     = "vnet5000"
}

variable "vlan_tag" {
  description = "VLAN tag on the bridge (vnet5000 is VLAN-aware)"
  type        = number
  default     = 32

  validation {
    condition     = var.vlan_tag >= 1 && var.vlan_tag <= 4094
    error_message = "VLAN tag must be between 1 and 4094."
  }
}

variable "clone_datastore" {
  description = "Datastore for the full clone - must be shared for cross-node placement"
  type        = string
  default     = "storage"
}

variable "iso_datastore" {
  description = "Datastore receiving the cloud-init seed ISO - must allow 'iso' content"
  type        = string
  default     = "ISO"
}

variable "cdrom_interface" {
  description = "Interface the cloud-init seed ISO is attached to"
  type        = string
  default     = "ide2"
}

variable "seed_iso_path" {
  description = "Local path to the cloud-init seed ISO built by scripts/build-niosx-seed.sh"
  type        = string
  default     = "seed.iso"
}
