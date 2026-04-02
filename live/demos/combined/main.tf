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

data "bloxone_ipam_next_available_subnets" "vpc_subnet" {
  id           = "ipam/address_block/${var.aws_block_id}"
  cidr         = var.subnet_size
  subnet_count = 1
}

resource "bloxone_ipam_subnet" "vpc_subnet" {
  address = replace(trimspace(data.bloxone_ipam_next_available_subnets.vpc_subnet.results[0]), "\"", "")
  cidr    = var.subnet_size
  space   = var.ipam_space_id
  name    = "${var.vpc_name}-subnet"
  comment = "Combined demo: AWS VPC ${var.vpc_name} in ${var.aws_region} — IPAM+VPC+DNS chain"

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

resource "aws_vpc" "main" {
  cidr_block           = "${replace(trimspace(data.bloxone_ipam_next_available_subnets.vpc_subnet.results[0]), "\"", "")}/${var.subnet_size}"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name       = var.vpc_name
    demo       = "true"
    Demo       = "true"
    ManagedBy  = "terraform"
    automation = "github-actions"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name       = "${var.vpc_name}-igw"
    demo       = "true"
    Demo       = "true"
    ManagedBy  = "terraform"
    automation = "github-actions"
  }
}

# =============================================================================
# Phase 3: DNS — Create A record pointing to VPC's first usable IP
# =============================================================================

data "bloxone_dns_auth_zones" "zone" {
  filters = {
    fqdn = var.zone_fqdn
  }
}

resource "bloxone_dns_a_record" "vpc_entry" {
  name_in_zone = var.record_name
  zone         = data.bloxone_dns_auth_zones.zone.results[0].id
  ttl          = 120
  comment      = "Combined demo: VPC ${var.vpc_name} entry point — auto-derived from IPAM allocation"

  tags = {
    "demo"       = "true"
    "automation" = "github-actions"
  }

  rdata = {
    address = cidrhost(aws_vpc.main.cidr_block, 1)
  }
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
  value       = bloxone_ipam_subnet.vpc_subnet.id
}

output "ipam_subnet_address" {
  description = "IPAM-allocated subnet address"
  value       = bloxone_ipam_subnet.vpc_subnet.address
}

output "dns_record_fqdn" {
  description = "Full DNS record FQDN"
  value       = "${var.record_name}.${var.zone_fqdn}"
}

output "dns_record_value" {
  description = "DNS A record value (first usable IP in VPC CIDR)"
  value       = cidrhost(aws_vpc.main.cidr_block, 1)
}
