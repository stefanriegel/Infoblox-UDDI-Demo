terraform {
  required_version = ">= 1.6"
  required_providers {
    bloxone = {
      source  = "infobloxopen/bloxone"
      version = ">= 1.5.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "bloxone" {
  csp_url = var.bloxone_host
  api_key = var.bloxone_api_key
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

# Allocate + reserve a subnet from the GCP IPAM block (see ../../../CONTEXT.md)
module "subnet" {
  source = "../../../modules/allocated_subnet"

  block_id    = var.gcp_block_id
  subnet_size = var.subnet_size
  space_id    = var.ipam_space_id
  name        = var.vpc_name
  comment     = "GCP VPC ${var.vpc_name} in ${var.gcp_region} - allocated from GCP block 10.43.0.0/16"
  parent_cidr = "10.43.0.0/16"

  tags = {
    "demo"       = "true"
    "automation" = "github-actions"
    "cloud"      = "gcp"
    "vpc_name"   = var.vpc_name
    "region"     = var.gcp_region
  }
}

# Preserve state across the move into the allocated_subnet module
moved {
  from = bloxone_ipam_subnet.vpc_subnet
  to   = module.subnet.bloxone_ipam_subnet.this
}

# Create GCP VPC Network (auto mode disabled for custom subnets)
resource "google_compute_network" "main" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  description             = "VPC managed by UDDI IPAM - ${var.vpc_name}"

  # GCP doesn't support tags at network level, using description instead
}

# Create GCP Subnet with UDDI-allocated CIDR
resource "google_compute_subnetwork" "main" {
  name          = "${var.vpc_name}-subnet-${var.gcp_region}"
  ip_cidr_range = module.subnet.cidr
  region        = var.gcp_region
  network       = google_compute_network.main.id

  description = "Subnet allocated by UDDI IPAM"
}

# Outputs
output "vpc_id" {
  value       = google_compute_network.main.id
  description = "GCP VPC Network ID"
}

output "vpc_name" {
  value       = google_compute_network.main.name
  description = "GCP VPC Network Name"
}

output "vpc_cidr" {
  value       = module.subnet.cidr
  description = "CIDR block allocated by UDDI IPAM"
}

output "subnet_id" {
  value       = google_compute_subnetwork.main.id
  description = "GCP Subnet ID"
}

output "gcp_region" {
  value       = var.gcp_region
  description = "GCP Region"
}

output "gcp_project_id" {
  value       = var.gcp_project_id
  description = "GCP Project ID"
}

output "uddi_subnet_id" {
  value       = module.subnet.subnet_id
  description = "UDDI IPAM Subnet ID"
}

output "parent_block" {
  value       = module.subnet.parent_cidr
  description = "GCP Reserved IPAM Block"
}
