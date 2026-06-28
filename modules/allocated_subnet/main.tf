# allocated_subnet — draw a next-available subnet from a UDDI IPAM block and
# reserve it back into UDDI. Hides the provider's quoted-string quirk and the
# CIDR mask assembly behind one interface. See ../../CONTEXT.md.

data "bloxone_ipam_next_available_subnets" "this" {
  id           = "ipam/address_block/${var.block_id}"
  cidr         = var.subnet_size
  subnet_count = 1
}

locals {
  # The provider returns each result as a quoted, whitespace-padded string.
  # Clean it once, here, so no caller has to know about the quirk.
  address = replace(trimspace(data.bloxone_ipam_next_available_subnets.this.results[0]), "\"", "")
  cidr    = "${local.address}/${var.subnet_size}"
}

resource "bloxone_ipam_subnet" "this" {
  address = local.address
  cidr    = var.subnet_size
  space   = var.space_id
  name    = var.name
  comment = var.comment
  tags    = var.tags
}
