terraform {
  required_version = ">= 1.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {
  # Identical payload to the AWS and Proxmox demos; Azure takes it as custom_data.
  user_data = <<-EOT
    #cloud-config
    host_setup:
      jointoken: ${var.niosx_join_token}
      tags:
        - demo=true
        - automation=github-actions
        - hostname=${var.name}
  EOT
}

resource "azurerm_resource_group" "main" {
  name     = "rg-${var.name}"
  location = var.azure_location

  tags = {
    demo       = "true"
    automation = "github-actions"
    managed_by = "terraform"
  }
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = [var.vnet_cidr]

  tags = {
    demo = "true"
  }
}

resource "azurerm_subnet" "main" {
  name                 = "snet-${var.name}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.vnet_cidr]
}

# Azure's default rules already allow all outbound and deny inbound from the
# internet, which is what the join needs. Only DNS from inside the VNet is added.
resource "azurerm_network_security_group" "main" {
  name                = "nsg-${var.name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "AllowDnsFromVnet"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "53"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  tags = {
    demo = "true"
  }
}

resource "azurerm_subnet_network_security_group_association" "main" {
  subnet_id                 = azurerm_subnet.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

resource "azurerm_public_ip" "main" {
  name                = "pip-${var.name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    demo = "true"
  }
}

resource "azurerm_network_interface" "main" {
  name                = "nic-${var.name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }

  tags = {
    demo = "true"
  }
}

# Azure requires an admin credential on every Linux VM even though NIOS-X does
# not expose SSH. This throwaway key satisfies the API and is never used.
resource "tls_private_key" "placeholder" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_linux_virtual_machine" "niosx" {
  name                            = var.name
  computer_name                   = var.name
  location                        = azurerm_resource_group.main.location
  resource_group_name             = azurerm_resource_group.main.name
  size                            = var.vm_size
  admin_username                  = "azureuser"
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.main.id]
  custom_data                     = base64encode(local.user_data)

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.placeholder.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_type
  }

  source_image_reference {
    publisher = "infoblox"
    offer     = "infoblox-nios-x-vm"
    sku       = "infoblox-nios-x-vm"
    version   = var.image_version
  }

  # Marketplace images require the plan block and accepted terms on the
  # subscription (az vm image terms accept --urn infoblox:...).
  plan {
    name      = "infoblox-nios-x-vm"
    publisher = "infoblox"
    product   = "infoblox-nios-x-vm"
  }

  tags = {
    demo       = "true"
    automation = "github-actions"
    managed_by = "terraform"
    product    = "niosx"
  }
}

output "vm_id" {
  value       = azurerm_linux_virtual_machine.niosx.id
  description = "Azure resource ID of the NIOS-X server"
}

output "vm_name" {
  value       = azurerm_linux_virtual_machine.niosx.name
  description = "Name of the NIOS-X server"
}

output "public_ip" {
  value       = azurerm_public_ip.main.ip_address
  description = "Public IP used to reach the Infoblox Portal"
}

output "private_ip" {
  value       = azurerm_network_interface.main.private_ip_address
  description = "Private IP inside the demo VNet"
}

output "vm_size" {
  value       = azurerm_linux_virtual_machine.niosx.size
  description = "Azure VM size"
}

output "resource_group_name" {
  value       = azurerm_resource_group.main.name
  description = "Resource group holding the demo"
}
