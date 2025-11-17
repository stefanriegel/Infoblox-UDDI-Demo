terraform {
  required_providers {
    bloxone = {
      source  = "infobloxopen/bloxone"
      version = ">= 1.5.0"
    }
  }
}

provider "bloxone" {
  csp_url = var.bloxone_host
  api_key = var.bloxone_api_key
}

# Load existing zone
data "bloxone_dns_auth_zones" "zone" {
  filters = {
    fqdn = var.zone_fqdn
  }
}

# A Record (conditional)
resource "bloxone_dns_a_record" "a_record" {
  count        = var.record_type == "A" ? 1 : 0
  name_in_zone = var.record_name
  zone         = data.bloxone_dns_auth_zones.zone.results[0].id
  ttl          = var.ttl
  comment      = "Terraform-managed A record"

  tags = {
    "demo" = "true"
    "automation" = "github-actions"
  }

  rdata = {
    address = var.record_value
  }
}

# AAAA Record (conditional)
resource "bloxone_dns_aaaa_record" "aaaa_record" {
  count        = var.record_type == "AAAA" ? 1 : 0
  name_in_zone = var.record_name
  zone         = data.bloxone_dns_auth_zones.zone.results[0].id
  ttl          = var.ttl
  comment      = "Terraform-managed AAAA record"

  tags = {
    "demo" = "true"
    "automation" = "github-actions"
  }

  rdata = {
    address = var.record_value
  }
}

# TXT Record (conditional)
resource "bloxone_dns_txt_record" "txt_record" {
  count        = var.record_type == "TXT" ? 1 : 0
  name_in_zone = var.record_name
  zone         = data.bloxone_dns_auth_zones.zone.results[0].id
  ttl          = var.ttl
  comment      = "Terraform-managed TXT record"

  tags = {
    "demo" = "true"
    "automation" = "github-actions"
  }

  rdata = {
    text = var.record_value
  }
}

# CNAME Record (conditional)
resource "bloxone_dns_cname_record" "cname_record" {
  count        = var.record_type == "CNAME" ? 1 : 0
  name_in_zone = var.record_name
  zone         = data.bloxone_dns_auth_zones.zone.results[0].id
  ttl          = var.ttl
  comment      = "Terraform-managed CNAME record"

  tags = {
    "demo" = "true"
    "automation" = "github-actions"
  }

  rdata = {
    cname = var.record_value
  }
}

# Outputs
output "zone_id" {
  description = "UDDI Zone ID"
  value       = data.bloxone_dns_auth_zones.zone.results[0].id
}

output "zone_fqdn" {
  description = "Zone FQDN"
  value       = data.bloxone_dns_auth_zones.zone.results[0].fqdn
}

output "record_id" {
  description = "Created record ID"
  value = try(
    bloxone_dns_a_record.a_record[0].id,
    bloxone_dns_aaaa_record.aaaa_record[0].id,
    bloxone_dns_txt_record.txt_record[0].id,
    bloxone_dns_cname_record.cname_record[0].id,
    null
  )
}
