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

# Allocate + reserve a subnet from the AWS IPAM block (see ../../../CONTEXT.md)
module "subnet" {
  source = "../../../modules/allocated_subnet"

  block_id    = var.aws_block_id
  subnet_size = var.subnet_size
  space_id    = var.ipam_space_id
  name        = "${var.vpc_name}-subnet"
  comment     = "AWS VPC ${var.vpc_name} in ${var.aws_region} - allocated from AWS block 10.42.0.0/16"
  parent_cidr = "10.42.0.0/16"

  tags = {
    "demo"       = "true"
    "automation" = "github-actions"
    "cloud"      = "aws"
    "vpc_name"   = var.vpc_name
    "region"     = var.aws_region
  }
}

# Preserve state across the move into the allocated_subnet module
moved {
  from = bloxone_ipam_subnet.vpc_subnet
  to   = module.subnet.bloxone_ipam_subnet.this
}

# Create AWS VPC with UDDI-allocated CIDR
resource "aws_vpc" "main" {
  cidr_block           = module.subnet.cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name         = var.vpc_name
    ManagedBy    = "terraform"
    Demo         = "true"
    UDDIReserved = module.subnet.parent_cidr
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
  value       = module.subnet.subnet_id
}

output "aws_region" {
  description = "AWS Region"
  value       = var.aws_region
}

output "parent_block" {
  description = "AWS Reserved IPAM Block"
  value       = module.subnet.parent_cidr
}
