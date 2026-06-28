variable "block_id" {
  description = "UDDI IPAM address block ID to allocate from (UUID, without the 'ipam/address_block/' prefix)."
  type        = string
}

variable "subnet_size" {
  description = "Subnet prefix length to allocate (e.g. 26 for a /26)."
  type        = number
}

variable "space_id" {
  description = "UDDI IPAM space ID to reserve the subnet in."
  type        = string
}

variable "name" {
  description = "Name for the reserved subnet in UDDI."
  type        = string
}

variable "comment" {
  description = "Comment for the reserved subnet in UDDI."
  type        = string
  default     = ""
}

variable "parent_cidr" {
  description = "Parent address block CIDR, for narration/display. Re-exported unchanged."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags applied to the reserved subnet."
  type        = map(string)
  default     = {}
}
