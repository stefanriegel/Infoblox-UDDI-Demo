output "cidr" {
  description = "Allocated subnet as a masked CIDR (e.g. 10.42.0.0/26), cleaned of provider quoting."
  value       = local.cidr
}

output "address" {
  description = "Allocated network address without mask (e.g. 10.42.0.0)."
  value       = local.address
}

output "subnet_id" {
  description = "ID of the reserved bloxone_ipam_subnet."
  value       = bloxone_ipam_subnet.this.id
}

output "parent_cidr" {
  description = "Parent address block CIDR, passed through from input."
  value       = var.parent_cidr
}
