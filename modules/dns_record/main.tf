# dns_record — create one DNS record of any supported type in a UDDI auth zone.
# Resolves the zone from its FQDN internally and owns the per-type rdata switch
# plus the record-id selection, so callers learn one interface. See ../../CONTEXT.md.

data "bloxone_dns_auth_zones" "this" {
  filters = {
    fqdn = var.zone_fqdn
  }
}

locals {
  zone_id = data.bloxone_dns_auth_zones.this.results[0].id
}

resource "bloxone_dns_a_record" "this" {
  count        = var.record_type == "A" ? 1 : 0
  name_in_zone = var.record_name
  zone         = local.zone_id
  ttl          = var.ttl
  comment      = var.comment
  tags         = var.tags

  rdata = {
    address = var.record_value
  }

  lifecycle {
    ignore_changes = [provider_metadata]
  }
}

resource "bloxone_dns_aaaa_record" "this" {
  count        = var.record_type == "AAAA" ? 1 : 0
  name_in_zone = var.record_name
  zone         = local.zone_id
  ttl          = var.ttl
  comment      = var.comment
  tags         = var.tags

  rdata = {
    address = var.record_value
  }

  lifecycle {
    ignore_changes = [provider_metadata]
  }
}

resource "bloxone_dns_txt_record" "this" {
  count        = var.record_type == "TXT" ? 1 : 0
  name_in_zone = var.record_name
  zone         = local.zone_id
  ttl          = var.ttl
  comment      = var.comment
  tags         = var.tags

  rdata = {
    text = var.record_value
  }

  lifecycle {
    ignore_changes = [provider_metadata]
  }
}

resource "bloxone_dns_cname_record" "this" {
  count        = var.record_type == "CNAME" ? 1 : 0
  name_in_zone = var.record_name
  zone         = local.zone_id
  ttl          = var.ttl
  comment      = var.comment
  tags         = var.tags

  rdata = {
    cname = var.record_value
  }

  lifecycle {
    ignore_changes = [provider_metadata]
  }
}
