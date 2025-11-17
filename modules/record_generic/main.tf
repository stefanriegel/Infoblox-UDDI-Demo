# A Record
resource "bloxone_dns_a_record" "a_record" {
  count        = var.record_type == "A" ? 1 : 0
  name_in_zone = var.record_name
  zone         = var.zone_fqdn
  ttl          = var.ttl
  comment      = "Terraform-managed A record"

  rdata = {
    address = var.record_value
  }
}

# AAAA Record
resource "bloxone_dns_aaaa_record" "aaaa_record" {
  count        = var.record_type == "AAAA" ? 1 : 0
  name_in_zone = var.record_name
  zone         = var.zone_fqdn
  ttl          = var.ttl
  comment      = "Terraform-managed AAAA record"

  rdata = {
    address = var.record_value
  }
}

# TXT Record
resource "bloxone_dns_txt_record" "txt_record" {
  count        = var.record_type == "TXT" ? 1 : 0
  name_in_zone = var.record_name
  zone         = var.zone_fqdn
  ttl          = var.ttl
  comment      = "Terraform-managed TXT record"

  rdata = {
    text = var.record_value
  }
}
