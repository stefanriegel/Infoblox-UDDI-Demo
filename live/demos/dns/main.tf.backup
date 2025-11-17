module "cf_zone" {
  source    = "../../modules/cf_zone"
  zone_fqdn = var.zone_fqdn
}

module "record_generic" {
  source       = "../../modules/record_generic"
  count        = var.record_type == "CNAME" ? 0 : 1
  zone_fqdn    = module.cf_zone.zone_id
  record_name  = var.record_name
  record_type  = var.record_type
  record_value = var.record_value
  ttl          = var.ttl
}

module "record_cname" {
  source       = "../../modules/record_cname"
  count        = var.record_type == "CNAME" ? 1 : 0
  zone_fqdn    = module.cf_zone.zone_id
  record_name  = var.record_name
  cname_target = var.record_value
  ttl          = var.ttl
}

# Outputs
output "zone_id" {
  description = "UDDI Zone ID"
  value       = module.cf_zone.zone_id
}

output "zone_fqdn" {
  description = "Zone FQDN (trailing dot)"
  value       = module.cf_zone.zone_fqdn
}

output "record_id" {
  description = "Record ID (generic or CNAME, whichever is active)"
  value       = try(module.record_generic[0].record_id, module.record_cname[0].record_id, null)
}

output "record_fqdn" {
  description = "Record FQDN (generic or CNAME, whichever is active)"
  value       = try(module.record_generic[0].record_fqdn, module.record_cname[0].record_fqdn, null)
}

output "cname_target" {
  description = "CNAME target (only if record_type == CNAME)"
  value       = try(module.record_cname[0].cname_target, null)
}
