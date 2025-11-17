variable "zone_fqdn" {
  description = "Authoritative Zone FQDN (trailing dot)."
  type        = string
  validation {
    condition     = can(regex("\\.$", var.zone_fqdn))
    error_message = "zone_fqdn must end with a trailing dot."
  }
}

variable "record_name" {
  description = "Source record label (e.g. 'app')."
  type        = string
}

variable "cname_target" {
  description = "Canonical target FQDN (must end with a dot)."
  type        = string
  validation {
    condition     = can(regex("\\.$", var.cname_target))
    error_message = "cname_target must end with a trailing dot."
  }
}

variable "ttl" {
  description = "TTL in seconds."
  type        = number
  default     = 60
}
