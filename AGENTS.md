# AGENTS.md - Infoblox UDDI Demo Project

## Purpose
This repository drives UDDI Automation demos through GitHub Actions workflows, demonstrating Infoblox Universal DDI capabilities for multi-cloud DNS and IPAM management.

## Build/Lint/Test Commands

**Terraform Version:** 1.6.6 (required)

**Init:** `terraform init`
**Validate:** `terraform validate -no-color`
**Format:** `terraform fmt -check -recursive` (lint) or `terraform fmt -recursive` (fix)
**Plan:** `terraform plan -input=false -no-color`
**Apply:** `terraform apply -auto-approve -no-color`
**Destroy:** `terraform destroy -auto-approve -no-color`

**Single Test:** Run in demo directory: `cd live/demos/dns && terraform plan`

## GitHub Actions
- **DNS Demo:** `.github/workflows/run-demo.yml` - Multi-cloud DNS record management (Cloudflare, Azure DNS, Route53, Cloud DNS)
- **VPC Demo:** `.github/workflows/vpc-deployment.yml` - IPAM-driven VPC/VNet provisioning
- **Cleanup:** `.github/workflows/cleanup.yml` - Automated resource cleanup

## Code Style Guidelines

**Language:** HCL (HashiCorp Configuration Language)

**Naming:**
- Variables: `snake_case` (e.g., `zone_fqdn`, `record_name`)
- Resources: `snake_case` (e.g., `bloxone_dns_a_record`)
- Outputs: `snake_case` (e.g., `zone_id`)

**Structure:**
- Required providers block first
- Provider configuration second
- Data sources, then resources, then outputs
- One resource per logical component

**Formatting:**
- 2-space indentation
- Align equals signs in blocks
- Blank lines between logical sections
- Comments for complex resources

**Types & Validation:**
- Explicit type declarations (`string`, `number`, `bool`)
- Validation blocks for complex constraints
- Mark sensitive variables with `sensitive = true`

**Error Handling:**
- Use `try()` function for conditional outputs
- Count parameters for conditional resources
- Validation blocks with clear error messages

**Imports:**
- Provider source with version constraints
- No external libraries beyond Terraform providers

**Tags:**
- Use consistent tagging: `demo = "true"`, `automation = "github-actions"`</content>
<parameter name="filePath">/Users/stefanriegel/Documents/coding/Infoblox-UDDI-Demo/AGENTS.md