terraform {
  required_version = ">= 1.5"
  required_providers {
    bloxone = {
      source  = "infobloxopen/bloxone"
      version = ">= 1.5.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "bloxone" {
  csp_url = var.bloxone_host
  api_key = var.bloxone_api_key
}

provider "aws" {
  region = var.aws_region
}

# Get next available subnet from AWS IPAM block (using direct block ID)
data "bloxone_ipam_next_available_subnets" "vpc_subnet" {
  id           = "ipam/address_block/${var.aws_block_id}"
  cidr         = var.subnet_size
  subnet_count = 1
}

# Create AWS VPC with UDDI-allocated CIDR
resource "aws_vpc" "main" {
  cidr_block           = "${replace(trimspace(data.bloxone_ipam_next_available_subnets.vpc_subnet.results[0]), "\"", "")}/${var.subnet_size}"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name         = var.vpc_name
    ManagedBy    = "terraform"
    Demo         = "true"
    UDDIReserved = "10.42.0.0/16"
  }
}

# Reserve the subnet in UDDI
resource "bloxone_ipam_subnet" "vpc_subnet" {
  address = replace(trimspace(data.bloxone_ipam_next_available_subnets.vpc_subnet.results[0]), "\"", "")
  cidr    = var.subnet_size
  space   = var.ipam_space_id
  name    = "${var.vpc_name}-subnet"
  comment = "AWS VPC ${var.vpc_name} in ${var.aws_region} - allocated from AWS block 10.42.0.0/16"
  
  tags = {
    "demo"       = "true"
    "automation" = "github-actions"
    "cloud"      = "aws"
    "vpc_name"   = var.vpc_name
    "region"     = var.aws_region
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.vpc_name}-igw"
    Demo = "true"
  }
}

# Outputs
output "vpc_id" {
  description = "AWS VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR Block (allocated from UDDI)"
  value       = aws_vpc.main.cidr_block
}

output "uddi_subnet_id" {
  description = "UDDI Subnet ID"
  value       = bloxone_ipam_subnet.vpc_subnet.id
}

output "aws_region" {
  description = "AWS Region"
  value       = var.aws_region
}

output "parent_block" {
  description = "AWS Reserved IPAM Block"
  value       = "10.42.0.0/16"
}
