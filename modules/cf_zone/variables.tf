variable "zone_fqdn" {
  description = "Authoritative Zone FQDN with trailing dot, e.g. virtualife.pro."
  type        = string
  validation {
    condition     = can(regex("\\.$", var.zone_fqdn))
    error_message = "zone_fqdn must end with a trailing dot (e.g. example.com.)."
  }
}
