# Infoblox UDDI Demo

## What This Is

A GitHub Actions-based demo repository showcasing Infoblox Universal DDI capabilities for multi-cloud DNS and IPAM management. SEs trigger workflows via the GitHub UI to demonstrate UDDI as a single source of truth for DNS records and IP address management across AWS, Azure, GCP, and Cloudflare. All automation is Terraform-driven using the BloxOne provider.

## Core Value

UDDI as the centralized control plane — one place to manage DNS and IP addressing, automatically synchronized to any cloud provider. The demo proves this with real infrastructure, not slides.

## Current State

**M001 (Customer Demo Enhancement) complete.** The demo suite is SE-ready with four polished workflows:

- **DNS Demo** (`run-demo.yml`) — Creates DNS records in UDDI, verifies sync to Cloudflare/Azure DNS/Route53/Cloud DNS. Narrated output with timing, Mermaid diagram, branded summary.
- **VPC Demo** (`vpc-deployment.yml`) — Allocates subnets from UDDI IPAM, provisions real VPCs/VNets on AWS/Azure/GCP. Bug fixed (empty verification tables), narrated output, Mermaid diagram, branded summary.
- **Combined Demo** (`combined-demo.yml`) — Chains IPAM allocation → VPC provisioning → DNS A record creation with narrated phases, DNS verification against 3 resolvers + Route53 API, and Mermaid job summary. The centerpiece demo showing UDDI's full value.
- **Cleanup** (`cleanup.yml`) — Tag-based cleanup across all providers including combined demo resources. Narrated output with Mermaid diagrams.

All workflows share consistent Infoblox UDDI branding (badge, title prefix, Mermaid color palette, value proposition footer), SE-friendly inputs with examples and sensible defaults, and boxed ASCII narration in logs. Cross-suite consistency is verified by `scripts/verify-s03.sh` (15 checks). Live GitHub Actions UAT is the remaining validation step.

## Architecture / Key Patterns

- **Terraform + BloxOne provider** for all UDDI interactions
- **GitHub Actions `workflow_dispatch`** for SE-triggered demos
- **UDDI-native sync** for DNS — records created in UDDI, verified on cloud providers (no dual-write)
- **UDDI IPAM next-available** for subnet allocation — conflict-free, centralized
- **Tag-based cleanup** (`demo=true`) for resource lifecycle
- Zones: `virtualife.pro` (Cloudflare), `az/aws/gcp.gh.blox42.rocks` (Azure/Route53/Cloud DNS)
- IPAM blocks: AWS `10.42.0.0/16`, Azure `10.44.0.0/16`, GCP `10.43.0.0/16`

- **Heredoc summary pattern** — HEADER (literal) + EOF (interpolated) + FOOTER (literal) for job summaries
- **Mermaid color palette** — UDDI #0066cc, AWS #FF9900, Azure #0078D4, GCP #4285F4, Verification #7B1FA2, Delete #dc3545
- **Boxed ASCII narration** — ╔══╗ banners for phase announcements in workflow logs
- **Cleanup tag convention** — Uppercase `Demo`/`ManagedBy` tags on all demo AWS resources

## Capability Contract

See `.gsd/REQUIREMENTS.md` for the explicit capability contract, requirement status, and coverage mapping.

## Milestone Sequence

- [x] M001: Customer Demo Enhancement — Combined IPAM+DNS workflow, professional narrated output, consistent branding, SE-friendly inputs across all 4 workflows. Static verification complete; live UAT pending.
