output "record_id" {
  description = "ID of the created record, whichever type was selected."
  value = try(
    bloxone_dns_a_record.this[0].id,
    bloxone_dns_aaaa_record.this[0].id,
    bloxone_dns_txt_record.this[0].id,
    bloxone_dns_cname_record.this[0].id,
    null
  )
}

output "zone_id" {
  description = "Resolved UDDI zone id."
  value       = local.zone_id
}

output "zone_fqdn" {
  description = "Zone FQDN, from the resolved zone."
  value       = data.bloxone_dns_auth_zones.this.results[0].fqdn
}

output "fqdn" {
  description = "Full record FQDN (record_name joined to zone_fqdn)."
  value       = var.record_name == "" ? var.zone_fqdn : "${var.record_name}.${var.zone_fqdn}"
}
