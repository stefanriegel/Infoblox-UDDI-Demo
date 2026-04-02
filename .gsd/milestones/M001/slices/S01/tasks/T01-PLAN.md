---
estimated_steps: 8
estimated_files: 2
---

# T01: Combined Terraform Root

**Slice:** S01 — Combined IPAM+DNS Workflow
**Milestone:** M001

## Description

Create a single Terraform configuration that chains IPAM allocation → VPC provisioning → DNS record creation. This is the infrastructure-as-code core of the combined demo. It follows existing patterns from `vpc-aws/main.tf` and `dns/main.tf` but combines them into one apply.

## Steps

1. Create `live/demos/combined/` directory
2. Write `variables.tf` with inputs: `bloxone_host`, `bloxone_api_key`, `vpc_name`, `subnet_size`, `aws_region`, `aws_block_id`, `ipam_space_id`, `zone_fqdn` (default `aws.gh.blox42.rocks.`), `record_name`
3. Write `main.tf` with providers block (bloxone + aws)
4. Add `bloxone_ipam_next_available_subnets` data source (pattern from `vpc-aws/main.tf`)
5. Add `bloxone_ipam_subnet` resource to reserve the allocation with tags `demo=true`, `automation=github-actions`, `cloud=aws`, `workflow=combined`
6. Add `aws_vpc` + `aws_internet_gateway` resources (pattern from `vpc-aws/main.tf`) with tags `Demo=true`, `ManagedBy=terraform`, `Workflow=combined`
7. Add `bloxone_dns_a_record` resource pointing `{record_name}.aws.gh.blox42.rocks.` to the first usable IP from the allocated CIDR (use `cidrhost()` function to derive IP from VPC CIDR)
8. Add outputs: `vpc_id`, `vpc_cidr`, `uddi_subnet_id`, `record_fqdn`, `record_ip`, `zone_fqdn`, `dns_record_id`

## Must-Haves

- [ ] `live/demos/combined/main.tf` exists with bloxone + aws providers, IPAM data source, IPAM subnet, aws_vpc, aws_internet_gateway, bloxone_dns_a_record
- [ ] `live/demos/combined/variables.tf` exists with all required variables and sensible defaults
- [ ] All resources tagged `demo=true` for cleanup discovery
- [ ] DNS record uses `cidrhost()` to derive a real IP from the VPC CIDR
- [ ] `terraform init && terraform validate` passes in `live/demos/combined/`

## Verification

- `cd live/demos/combined && terraform init -backend=false && terraform validate`
- File has ≥5 resource/data blocks (IPAM data, IPAM subnet, VPC, IGW, DNS record)
- All outputs reference real resource attributes

## Inputs

- `live/demos/vpc-aws/main.tf` — Pattern for IPAM allocation + VPC creation
- `live/demos/dns/main.tf` — Pattern for DNS record creation in UDDI
- D001: UDDI-native sync only
- D002: AWS as default cloud provider
- D003: Tag everything `demo=true`

## Expected Output

- `live/demos/combined/main.tf` — Complete Terraform root combining IPAM + VPC + DNS
- `live/demos/combined/variables.tf` — Input variables with defaults
