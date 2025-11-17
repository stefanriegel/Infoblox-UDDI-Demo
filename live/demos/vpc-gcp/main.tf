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

# Get next available subnet from GCP IPAM block using direct ID
data "bloxone_ipam_next_available_subnets" "vpc_subnet" {
  id           = "ipam/address_block/${var.gcp_block_id}"
  cidr         = var.subnet_size
  subnet_count = 1
}

# Reserve subnet in UDDI with tags
resource "bloxone_ipam_subnet" "vpc_subnet" {
  address = replace(trimspace(data.bloxone_ipam_next_available_subnets.vpc_subnet.results[0]), "\"", "")
  cidr    = var.subnet_size
  space   = var.ipam_space_id
  name    = var.vpc_name
  comment = "GCP VPC ${var.vpc_name} in ${var.gcp_region} - allocated from GCP block 10.43.0.0/16"

  tags = {
    "demo"       = "true"
    "automation" = "github-actions"
    "cloud"      = "gcp"
    "vpc_name"   = var.vpc_name
    "region"     = var.gcp_region
  }
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
  ip_cidr_range = "${replace(trimspace(data.bloxone_ipam_next_available_subnets.vpc_subnet.results[0]), "\"", "")}/${var.subnet_size}"
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
  value       = "${replace(trimspace(data.bloxone_ipam_next_available_subnets.vpc_subnet.results[0]), "\"", "")}/${var.subnet_size}"
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
  value       = bloxone_ipam_subnet.vpc_subnet.id
  description = "UDDI IPAM Subnet ID"
}

output "parent_block" {
  value       = "10.43.0.0/16"
  description = "GCP Reserved IPAM Block"
}
