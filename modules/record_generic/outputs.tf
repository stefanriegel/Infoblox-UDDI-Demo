locals {
  zone_nodot  = trimsuffix(var.zone_fqdn, ".")
  record_fqdn = var.record_name == "" ? "${local.zone_nodot}." : "${var.record_name}.${local.zone_nodot}."
}

output "record_id" {
  description = "UDDI record object ID"
  value       = try(
    bloxone_dns_a_record.a_record[0].id,
    bloxone_dns_aaaa_record.aaaa_record[0].id,
    bloxone_dns_txt_record.txt_record[0].id,
    null
  )
}

output "record_fqdn" {
  description = "FQDN of the created record with trailing dot"
  value       = local.record_fqdn
}
