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

# --- Providers ---

provider "bloxone" {
  csp_url = var.bloxone_host
  api_key = var.bloxone_api_key
}

provider "aws" {
  region = var.aws_region
}

# =============================================================================
# Phase 1: IPAM — Allocate next available subnet from AWS block
# =============================================================================

module "subnet" {
  source = "../../../modules/allocated_subnet"

  block_id    = var.aws_block_id
  subnet_size = var.subnet_size
  space_id    = var.ipam_space_id
  name        = "${var.vpc_name}-subnet"
  comment     = "Combined demo: AWS VPC ${var.vpc_name} in ${var.aws_region} — IPAM+VPC+DNS chain"
  parent_cidr = "10.42.0.0/16"

  tags = {
    "demo"       = "true"
    "automation" = "github-actions"
    "cloud"      = "aws"
    "vpc_name"   = var.vpc_name
    "region"     = var.aws_region
  }
}

# =============================================================================
# Phase 2: VPC — Provision AWS VPC using UDDI-allocated CIDR
# =============================================================================

# Preserve state across the move into the allocated_subnet module
moved {
  from = bloxone_ipam_subnet.vpc_subnet
  to   = module.subnet.bloxone_ipam_subnet.this
}

resource "aws_vpc" "main" {
  cidr_block           = module.subnet.cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  # AWS cleanup filters on PascalCase Demo + ManagedBy — see ADR-0002.
  tags = {
    Name      = var.vpc_name
    Demo      = "true"
    ManagedBy = "terraform"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  # AWS cleanup filters on PascalCase Demo + ManagedBy — see ADR-0002.
  tags = {
    Name      = "${var.vpc_name}-igw"
    Demo      = "true"
    ManagedBy = "terraform"
  }
}

# =============================================================================
# Phase 3: DNS — Create A record pointing to VPC's first usable IP
# =============================================================================

locals {
  # First usable IP in the VPC CIDR — the VPC's DNS entry point.
  vpc_entry_ip = cidrhost(aws_vpc.main.cidr_block, 1)
}

module "record" {
  source = "../../../modules/dns_record"

  zone_fqdn    = var.zone_fqdn
  record_name  = var.record_name
  record_type  = "A"
  record_value = local.vpc_entry_ip
  comment      = "Combined demo: VPC ${var.vpc_name} entry point — auto-derived from IPAM allocation"

  tags = {
    "demo"       = "true"
    "automation" = "github-actions"
  }
}

# Preserve state across the move into the dns_record module
moved {
  from = bloxone_dns_a_record.vpc_entry
  to   = module.record.bloxone_dns_a_record.this
}

# =============================================================================
# Outputs — consumed by GitHub Actions workflow for narration and verification
# =============================================================================

output "vpc_id" {
  description = "AWS VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR Block (allocated from UDDI IPAM)"
  value       = aws_vpc.main.cidr_block
}

output "subnet_id" {
  description = "UDDI IPAM Subnet ID"
  value       = module.subnet.subnet_id
}

output "ipam_subnet_address" {
  description = "IPAM-allocated subnet address"
  value       = module.subnet.address
}

output "dns_record_fqdn" {
  description = "Full DNS record FQDN"
  value       = module.record.fqdn
}

output "dns_record_value" {
  description = "DNS A record value (first usable IP in VPC CIDR)"
  value       = local.vpc_entry_ip
}
