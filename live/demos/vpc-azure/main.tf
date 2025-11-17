terraform {
  required_version = ">= 1.6"
  required_providers {
    bloxone = {
      source  = "infobloxopen/bloxone"
      version = ">= 1.5.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "bloxone" {
  csp_url = var.bloxone_host
  api_key = var.bloxone_api_key
}

provider "azurerm" {
  features {}
}

# Get next available subnet from Azure IPAM block using direct ID
data "bloxone_ipam_next_available_subnets" "vnet_subnet" {
  id           = "ipam/address_block/${var.azure_block_id}"
  cidr         = var.subnet_size
  subnet_count = 1
}

# Reserve subnet in UDDI with tags
resource "bloxone_ipam_subnet" "vnet_subnet" {
  address = replace(trimspace(data.bloxone_ipam_next_available_subnets.vnet_subnet.results[0]), "\"", "")
  cidr    = var.subnet_size
  space   = var.ipam_space_id
  name    = var.vnet_name
  comment = "Azure VNet ${var.vnet_name} in ${var.azure_location} - allocated from Azure block 10.44.0.0/16"

  tags = {
    "demo"       = "true"
    "automation" = "github-actions"
    "cloud"      = "azure"
    "vnet_name"  = var.vnet_name
    "region"     = var.azure_location
  }
}

# Create Azure Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.vnet_name}"
  location = var.azure_location

  tags = {
    demo       = "true"
    automation = "github-actions"
    managed_by = "terraform"
    uddi_ipam  = "true"
  }
}

# Create Azure VNet with UDDI-allocated CIDR
resource "azurerm_virtual_network" "main" {
  name                = var.vnet_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["${replace(trimspace(data.bloxone_ipam_next_available_subnets.vnet_subnet.results[0]), "\"", "")}/${var.subnet_size}"]

  tags = {
    demo       = "true"
    automation = "github-actions"
    managed_by = "terraform"
    uddi_ipam  = "true"
  }
}

# Outputs
output "vnet_id" {
  value       = azurerm_virtual_network.main.id
  description = "Azure VNet ID"
}

output "vnet_name" {
  value       = azurerm_virtual_network.main.name
  description = "Azure VNet Name"
}

output "vnet_cidr" {
  value       = "${replace(trimspace(data.bloxone_ipam_next_available_subnets.vnet_subnet.results[0]), "\"", "")}/${var.subnet_size}"
  description = "CIDR block allocated by UDDI IPAM"
}

output "resource_group_name" {
  value       = azurerm_resource_group.main.name
  description = "Azure Resource Group Name"
}

output "azure_location" {
  value       = azurerm_resource_group.main.location
  description = "Azure Location"
}

output "uddi_subnet_id" {
  value       = bloxone_ipam_subnet.vnet_subnet.id
  description = "UDDI IPAM Subnet ID"
}

output "parent_block" {
  value       = "10.44.0.0/16"
  description = "Azure Reserved IPAM Block"
}
