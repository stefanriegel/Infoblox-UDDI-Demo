output "zone_id" {
  description = "BloxOne/UDDI Zone ID"
  value       = data.bloxone_dns_auth_zones.this.results[0].id
}

output "zone_fqdn" {
  description = "Zone FQDN with trailing dot"
  value       = data.bloxone_dns_auth_zones.this.results[0].fqdn
}
