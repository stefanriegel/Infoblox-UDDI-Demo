variable "zone_fqdn" {
  description = "Authoritative zone FQDN with trailing dot (e.g. example.com.). Resolved to a zone id internally."
  type        = string
  validation {
    condition     = can(regex("\\.$", var.zone_fqdn))
    error_message = "zone_fqdn must end with a trailing dot."
  }
}

variable "record_name" {
  description = "Left-hand record label (e.g. 'www'). Use '' for the zone apex."
  type        = string
  default     = "www"
}

variable "record_type" {
  description = "Record type: A | AAAA | TXT | CNAME."
  type        = string
  validation {
    condition     = contains(["A", "AAAA", "TXT", "CNAME"], var.record_type)
    error_message = "record_type must be one of: A, AAAA, TXT, CNAME."
  }
}

variable "record_value" {
  description = "IPv4/IPv6 for A/AAAA, target FQDN (with dot) for CNAME, text for TXT."
  type        = string
}

variable "ttl" {
  description = "TTL in seconds."
  type        = number
  default     = 120
}

variable "comment" {
  description = "Comment stored on the record."
  type        = string
  default     = "Terraform-managed record"
}

variable "tags" {
  description = "Tags applied to the record."
  type        = map(string)
  default     = {}
}
