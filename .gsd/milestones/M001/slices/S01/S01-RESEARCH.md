# S01: Combined IPAM+DNS Workflow — Research

**Date:** 2026-04-02
**Depth:** Targeted (known patterns, new combination)

## Summary

The combined IPAM+DNS demo merges two existing, proven patterns into a single Terraform root and GitHub Actions workflow. The VPC-AWS demo (`live/demos/vpc-aws/`) already demonstrates IPAM allocation → VPC creation, and the DNS demo (`live/demos/dns/`) already demonstrates UDDI DNS record creation with Route53 verification. The combined demo chains them: allocate subnet → create VPC → create DNS A record pointing to a derived IP from the VPC CIDR → verify via Route53 API and dig.

The primary risk is not technical complexity but **wiring correctness** — ensuring Terraform resource references chain properly (IPAM output → VPC input → DNS input) and the workflow passes the right variables at each stage. The existing DNS workflow's Route53 verification and job summary generation (`run-demo.yml`, lines ~130-1063) is the gold standard to replicate for the combined workflow's summary.

## Recommendation

**Build the Terraform root first (T01), then the workflow (T02), then verify coherence (T03).** This is the natural dependency chain — the workflow can't be written until the Terraform outputs are known, and verification can't happen until both exist.

For the Terraform root, directly merge `vpc-aws/main.tf` and `dns/main.tf` patterns. The key design choice is how to derive the DNS A record value from the VPC CIDR. Use the first usable IP from the allocated subnet (e.g., `10.42.1.1` from `10.42.1.0/24`) via Terraform's `cidrhost()` function. This gives the demo a realistic "this VPC's entry point is now DNS-resolvable" story.

For the workflow, follow the DNS workflow's structure but add IPAM and VPC narration phases before the DNS phase. The job summary should show a 3-stage Mermaid diagram (IPAM → VPC → DNS) instead of the current single-stage DNS diagram.

## Implementation Landscape

### Key Files

- **`live/demos/vpc-aws/main.tf`** — Source pattern for IPAM allocation + VPC creation. Uses `bloxone_ipam_next_available_subnets` data source, `bloxone_ipam_subnet` resource, `aws_vpc`, and `aws_internet_gateway`. Variables: `bloxone_api_key`, `vpc_name`, `subnet_size`, `aws_region`, `aws_block_id`, `ipam_space_id`.
- **`live/demos/vpc-aws/variables.tf`** — Variable definitions with validation (subnet_size 16-28). Note: `subnet_size` is a `number` type here, used as CIDR prefix length.
- **`live/demos/dns/main.tf`** — Source pattern for DNS record creation. Uses `bloxone_dns_auth_zones` data source to look up zone by FQDN, then conditional record resources. For combined demo, only the A record path is needed.
- **`live/demos/dns/variables.tf`** — DNS variable definitions. Note: `zone_fqdn` requires trailing dot (validated with regex).
- **`.github/workflows/run-demo.yml`** — Gold standard for workflow structure. Key patterns to reuse: (1) DNS verification via dig to 3 resolvers, (2) Route53 API verification with `aws route53 list-resource-record-sets`, (3) Job summary with Mermaid diagram, status badges, config table, verification results, and value proposition footer. (4) State caching with `actions/cache`.
- **`.github/workflows/vpc-deployment.yml`** — Shows VPC workflow input patterns (network_name, subnet_size as choice, region as choice, action as choice). Also shows the preflight validation job pattern.

### Files to Create

- **`live/demos/combined/main.tf`** — Merged Terraform: providers (bloxone + aws) → IPAM allocation → subnet reservation → VPC creation → IGW → DNS zone lookup → DNS A record. Chain: `data.bloxone_ipam_next_available_subnets` → `bloxone_ipam_subnet` + `aws_vpc` → `bloxone_dns_a_record` using `cidrhost(aws_vpc.main.cidr_block, 1)` as the record value.
- **`live/demos/combined/variables.tf`** — Superset of vpc-aws + dns variables: `bloxone_api_key`, `bloxone_host`, `vpc_name`, `subnet_size`, `aws_region`, `aws_block_id`, `ipam_space_id`, `zone_fqdn` (default `aws.gh.blox42.rocks.`), `record_name`.
- **`.github/workflows/combined-demo.yml`** — Combined workflow with inputs, narrated steps, DNS verification, and professional job summary.

### Build Order

1. **T01: Terraform root** (`live/demos/combined/main.tf` + `variables.tf`) — This is the foundation. Merge VPC-AWS and DNS patterns. The key new element is chaining VPC CIDR → DNS A record value via `cidrhost()`. Verify with `terraform init && terraform validate`.
2. **T02: Workflow file** (`.github/workflows/combined-demo.yml`) — Depends on T01 outputs being defined. Structure: checkout → setup terraform → cache restore → init → plan/apply → extract outputs → DNS verification (dig + Route53 API) → job summary. Include timing with `date +%s` around key phases.
3. **T03: Coherence verification** — Review variable wiring between workflow and Terraform. Ensure cache key, FQDN construction, and destroy path all work.

### Verification Approach

- **T01:** `cd live/demos/combined && terraform init && terraform validate` must pass. Inspect outputs match what the workflow will need.
- **T02:** YAML lint (valid YAML). Check all `${{ inputs.X }}` and `${{ secrets.X }}` references are defined. Check all `${{ steps.X.outputs.Y }}` references have corresponding step IDs.
- **T03:** Cross-reference: every `-var="X=${{ ... }}"` in the workflow has a matching variable in `variables.tf`. The FQDN construction `${record_name}.aws.gh.blox42.rocks.` matches the zone_fqdn default. The cache key pattern is unique to combined workflow.
- **End-to-end:** Trigger workflow manually on GitHub Actions (requires live credentials). This is integration verification — not automatable locally.

## Constraints

- **Terraform 1.6.6** pinned in workflows — no features from newer versions.
- **`aws_block_id` and `ipam_space_id`** are UUIDs stored as GitHub secrets — the combined workflow needs these same secrets from the `dev` environment.
- **Zone `aws.gh.blox42.rocks.`** is the Route53-synced zone (per DNS workflow pattern). The combined demo must use this zone for the DNS A record.
- **UDDI-native sync only** (D001) — the DNS record is created in UDDI and UDDI syncs to Route53. The workflow verifies the sync happened but doesn't create anything directly in Route53.
- **`cidrhost()` quirk** — `cidrhost(cidr, 0)` gives the network address; use `cidrhost(cidr, 1)` for first usable host IP.

## Common Pitfalls

- **VPC CIDR construction** — The existing `vpc-aws/main.tf` has a fragile CIDR construction: `"${replace(trimspace(...), "\"", "")}/${var.subnet_size}"`. The `bloxone_ipam_next_available_subnets` data source returns just the network address (e.g., `10.42.1.0`), and the subnet size is appended. The combined demo should replicate this exact pattern to avoid mismatches.
- **State cache key collision** — If the combined workflow uses a generic cache key, it could restore DNS-only or VPC-only state. Use a unique prefix like `tfstate-combined-${{ inputs.vpc_name }}` to isolate.
- **GitHub secret masking in summaries** — The DNS workflow avoids GitHub's automatic secret masking by using literal zone names in summary output instead of referencing secrets. The combined workflow must do the same for `aws.gh.blox42.rocks`.
- **DNS propagation timing** — Route53 verification needs a sleep (10-30s) after Terraform apply for UDDI→Route53 sync. The DNS workflow uses `sleep 10`. The combined demo should use a similar or slightly longer delay since more resources are being created.

## Open Risks

- **IPAM block exhaustion** — If previous demo runs consumed all available subnets in the AWS block and cleanup hasn't run, the `next_available_subnets` data source will fail. Mitigation: the cleanup workflow should handle combined demo resources (deferred to S03).
- **Route53 hosted zone ID** — The DNS workflow uses `ROUTE53_HOSTED_ZONE_ID` secret for verification. Need to confirm this secret exists in the `dev` environment and maps to the `aws.gh.blox42.rocks` zone.
