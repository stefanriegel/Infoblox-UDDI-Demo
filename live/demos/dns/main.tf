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

# Create the requested record (any type) in the auth zone (see ../../../CONTEXT.md)
module "record" {
  source = "../../../modules/dns_record"

  zone_fqdn    = var.zone_fqdn
  record_name  = var.record_name
  record_type  = var.record_type
  record_value = var.record_value
  ttl          = var.ttl

  tags = {
    "demo"       = "true"
    "automation" = "github-actions"
  }
}

# Preserve state across the move into the dns_record module
moved {
  from = bloxone_dns_a_record.a_record
  to   = module.record.bloxone_dns_a_record.this
}

moved {
  from = bloxone_dns_aaaa_record.aaaa_record
  to   = module.record.bloxone_dns_aaaa_record.this
}

moved {
  from = bloxone_dns_txt_record.txt_record
  to   = module.record.bloxone_dns_txt_record.this
}

moved {
  from = bloxone_dns_cname_record.cname_record
  to   = module.record.bloxone_dns_cname_record.this
}

# Outputs
output "zone_id" {
  description = "UDDI Zone ID"
  value       = module.record.zone_id
}

output "zone_fqdn" {
  description = "Zone FQDN"
  value       = module.record.zone_fqdn
}

output "record_id" {
  description = "Created record ID"
  value       = module.record.record_id
}
