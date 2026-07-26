terraform {
  required_version = ">= 1.6"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.80.0"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = var.proxmox_insecure
}

# Cluster nodes - used to auto-pick a target node when none is given.
data "proxmox_virtual_environment_nodes" "cluster" {}

locals {
  online_nodes = [
    for idx, name in data.proxmox_virtual_environment_nodes.cluster.names :
    name if data.proxmox_virtual_environment_nodes.cluster.online[idx]
  ]

  # Empty proxmox_node = auto-pick the first online node. Safe across the whole
  # cluster because both the clone datastore and the ISO datastore are shared
  # (NFS) and the vnet lives in a VXLAN zone spanning every node.
  target_node = var.proxmox_node != "" ? var.proxmox_node : local.online_nodes[0]

  seed_iso_name = "${var.vm_name}-seed.iso"
}

# NoCloud seed image holding the NIOS-X cloud-init user-data (join token).
# Uploaded through the Proxmox API - no SSH access to the node required.
# Built beforehand by scripts/build-niosx-seed.sh.
resource "proxmox_virtual_environment_file" "niosx_seed" {
  content_type = "iso"
  datastore_id = var.iso_datastore
  node_name    = local.target_node

  source_file {
    path      = var.seed_iso_path
    file_name = local.seed_iso_name
  }
}

# Full clone of the NIOS-X template, seeded with cloud-init and started.
resource "proxmox_virtual_environment_vm" "niosx" {
  name        = var.vm_name
  description = "NIOS-X server cloned from template ${var.template_vm_id} - Infoblox UDDI demo"
  node_name   = local.target_node
  pool_id     = var.resource_pool
  tags        = ["demo", "terraform", "niosx"]

  clone {
    vm_id        = var.template_vm_id
    node_name    = var.template_node
    datastore_id = var.clone_datastore
    full         = true
  }

  # NIOS-X ships without qemu-guest-agent - leaving this enabled makes
  # Terraform block waiting for an IP that is never reported.
  agent {
    enabled = false
  }

  cpu {
    cores = var.vm_cores
    type  = "host"
  }

  memory {
    dedicated = var.vm_memory
  }

  # cloud-init seed. ide2 is the template's free CD-ROM slot; it sits first in
  # the template boot order but the seed image has no boot sector, so the BIOS
  # falls through to scsi0.
  cdrom {
    enabled   = true
    file_id   = proxmox_virtual_environment_file.niosx_seed.id
    interface = var.cdrom_interface
  }

  # Single management NIC, matching the Infoblox KVM reference deployment.
  # The template carries a second unused NIC that is not cloned forward.
  network_device {
    bridge  = var.network_bridge
    vlan_id = var.vlan_tag
    model   = "virtio"
  }

  started         = true
  stop_on_destroy = true
}

output "vm_id" {
  value       = proxmox_virtual_environment_vm.niosx.vm_id
  description = "VMID of the cloned NIOS-X server"
}

output "vm_name" {
  value       = proxmox_virtual_environment_vm.niosx.name
  description = "Name of the cloned NIOS-X server"
}

output "node_name" {
  value       = local.target_node
  description = "Proxmox node hosting the cloned NIOS-X server"
}

output "resource_pool" {
  value       = var.resource_pool
  description = "Proxmox resource pool the NIOS-X server belongs to"
}

output "mac_address" {
  value       = proxmox_virtual_environment_vm.niosx.network_device[0].mac_address
  description = "MAC address of the NIOS-X management interface"
}

output "network" {
  value = {
    bridge   = var.network_bridge
    vlan_tag = var.vlan_tag
  }
  description = "Bridge and VLAN tag the NIOS-X server is attached to"
}

output "seed_iso_volume_id" {
  value       = proxmox_virtual_environment_file.niosx_seed.id
  description = "Proxmox volume ID of the uploaded cloud-init seed image"
}
