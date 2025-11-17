variable "bloxone_host" {
  description = "BloxOne/UDDI API host"
  type        = string
  default     = "https://csp.infoblox.com"
}

variable "bloxone_api_key" {
  description = "BloxOne/UDDI API key (sensitive; provide via environment/secret)"
  type        = string
  sensitive   = true
}

variable "zone_fqdn" {
  description = "Authoritative Zone FQDN with trailing dot (e.g. virtualife.pro.)"
  type        = string
  default     = "virtualife.pro."
  validation {
    condition     = can(regex("\\.$", var.zone_fqdn))
    error_message = "zone_fqdn must end with a trailing dot."
  }
}

variable "record_name" {
  description = "Record label (e.g. www)"
  type        = string
  default     = "www"
}

variable "record_type" {
  description = "A | AAAA | TXT | CNAME"
  type        = string
  default     = "A"
  validation {
    condition     = contains(["A", "AAAA", "TXT", "CNAME"], var.record_type)
    error_message = "record_type must be one of: A, AAAA, TXT, CNAME."
  }
}

variable "record_value" {
  description = "Value: IPv4/IPv6 for A/AAAA, target FQDN (with dot) for CNAME, text for TXT"
  type        = string
  default     = "203.0.113.10"
}

variable "ttl" {
  description = "TTL in seconds"
  type        = number
  default     = 120
}

variable "orange_cloud" {
  description = "Enable Cloudflare Orange Cloud (proxy) for A/AAAA/CNAME records"
  type        = bool
  default     = false
}
