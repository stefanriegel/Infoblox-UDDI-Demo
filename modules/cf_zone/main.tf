# Load existing zone from UDDI (zone must already exist and be configured with Cloudflare)
data "bloxone_dns_auth_zones" "this" {
  filters = {
    fqdn = var.zone_fqdn
  }
}
