variable "zone_fqdn" {
  description = "Authoritative Zone FQDN (trailing dot)."
  type        = string
  validation {
    condition     = can(regex("\\.$", var.zone_fqdn))
    error_message = "zone_fqdn must end with a trailing dot."
  }
}

variable "record_name" {
  description = "Left-hand record label (e.g. 'www'). Use '' for zone apex."
  type        = string
  default     = "www"
}

variable "record_type" {
  description = "Record type: A | AAAA | TXT"
  type        = string
  validation {
    condition     = contains(["A", "AAAA", "TXT"], var.record_type)
    error_message = "record_type must be one of: A, AAAA, TXT."
  }
}

variable "record_value" {
  description = "IP (A/AAAA) or text (TXT; without surrounding quotes)."
  type        = string
}

variable "ttl" {
  description = "TTL in seconds."
  type        = number
  default     = 120
}
