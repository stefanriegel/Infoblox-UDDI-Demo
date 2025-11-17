terraform {
  required_version = ">= 1.4.0"

  required_providers {
    bloxone = {
      source  = "infobloxopen/bloxone"
      version = "~> 1.5.1"
    }
  }
}

provider "bloxone" {
  csp_url = var.bloxone_host
  api_key = var.bloxone_api_key
}
