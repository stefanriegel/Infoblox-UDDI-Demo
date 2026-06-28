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

# Allocate + reserve a subnet from the Azure IPAM block (see ../../../CONTEXT.md)
module "subnet" {
  source = "../../../modules/allocated_subnet"

  block_id    = var.azure_block_id
  subnet_size = var.subnet_size
  space_id    = var.ipam_space_id
  name        = var.vnet_name
  comment     = "Azure VNet ${var.vnet_name} in ${var.azure_location} - allocated from Azure block 10.44.0.0/16"
  parent_cidr = "10.44.0.0/16"

  tags = {
    "demo"       = "true"
    "automation" = "github-actions"
    "cloud"      = "azure"
    "vnet_name"  = var.vnet_name
    "region"     = var.azure_location
  }
}

# Preserve state across the move into the allocated_subnet module
moved {
  from = bloxone_ipam_subnet.vnet_subnet
  to   = module.subnet.bloxone_ipam_subnet.this
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

locals {
  vnet_cidr    = module.subnet.cidr
  subnet_names = ["web", "app", "data"]
  subnet_cidrs = [for i in range(length(local.subnet_names)) : cidrsubnet(local.vnet_cidr, 2, i)]
}

# Create Azure VNet with UDDI-allocated CIDR
resource "azurerm_virtual_network" "main" {
  name                = var.vnet_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = [local.vnet_cidr]

  tags = {
    demo       = "true"
    automation = "github-actions"
    managed_by = "terraform"
    uddi_ipam  = "true"
  }
}

# Create 3 Subnets within the VNet (web / app / data tiers)
resource "azurerm_subnet" "main" {
  for_each = { for idx, name in local.subnet_names : name => local.subnet_cidrs[idx] }

  name                 = "snet-${var.vnet_name}-${each.key}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [each.value]
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
  value       = local.vnet_cidr
  description = "CIDR block allocated by UDDI IPAM"
}

output "subnets" {
  value = {
    for k, s in azurerm_subnet.main : k => {
      id   = s.id
      cidr = s.address_prefixes[0]
    }
  }
  description = "Azure Subnets created within the VNet (web/app/data)"
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
  value       = module.subnet.subnet_id
  description = "UDDI IPAM Subnet ID"
}

output "parent_block" {
  value       = module.subnet.parent_cidr
  description = "Azure Reserved IPAM Block"
}
