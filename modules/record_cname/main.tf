resource "bloxone_dns_cname_record" "this" {
  name_in_zone = var.record_name
  zone         = var.zone_fqdn
  ttl          = var.ttl
  comment      = "Terraform-managed CNAME record"

  rdata = {
    cname = var.cname_target
  }
}
