# Infoblox UDDI Demo

## What This Is

A GitHub Actions-based demo repository showcasing Infoblox Universal DDI capabilities for multi-cloud DNS and IPAM management. SEs trigger workflows via the GitHub UI to demonstrate UDDI as a single source of truth for DNS records and IP address management across AWS, Azure, GCP, and Cloudflare. All automation is Terraform-driven using the BloxOne provider.

## Core Value

UDDI as the centralized control plane — one place to manage DNS and IP addressing, automatically synchronized to any cloud provider. The demo proves this with real infrastructure, not slides.

## Current State

Four workflows exist:
- **DNS Demo** (`run-demo.yml`) — Creates DNS records in UDDI, verifies sync to Cloudflare/Azure DNS/Route53/Cloud DNS
- **VPC Demo** (`vpc-deployment.yml`) — Allocates subnets from UDDI IPAM, provisions real VPCs/VNets on AWS/Azure/GCP
- **Combined Demo** (`combined-demo.yml`) — **NEW** — Chains IPAM allocation → VPC provisioning → DNS A record creation with narrated phases, DNS verification, and Mermaid job summary
- **Cleanup** (`cleanup.yml`) — Tag-based daily cleanup across all providers

S01 complete: combined workflow built and statically verified. S02 complete: all three existing workflows (DNS, VPC, Cleanup) have professional narrated output with consistent UDDI branding, Mermaid diagrams, timing metrics, and value proposition footers. VPC summary bug (empty verification tables) fixed. S03 complete: all 4 workflows polished with SE-friendly inputs, consistent branding (4/4 badge coverage), cleanup-discoverable tags on combined demo resources, and a 15-check cross-suite verification script. All slices statically verified; live GitHub Actions UAT pending.

## Architecture / Key Patterns

- **Terraform + BloxOne provider** for all UDDI interactions
- **GitHub Actions `workflow_dispatch`** for SE-triggered demos
- **UDDI-native sync** for DNS — records created in UDDI, verified on cloud providers (no dual-write)
- **UDDI IPAM next-available** for subnet allocation — conflict-free, centralized
- **Tag-based cleanup** (`demo=true`) for resource lifecycle
- Zones: `virtualife.pro` (Cloudflare), `az/aws/gcp.gh.blox42.rocks` (Azure/Route53/Cloud DNS)
- IPAM blocks: AWS `10.42.0.0/16`, Azure `10.44.0.0/16`, GCP `10.43.0.0/16`

## Capability Contract

See `.gsd/REQUIREMENTS.md` for the explicit capability contract, requirement status, and coverage mapping.

## Milestone Sequence

- [ ] M001: Customer Demo Enhancement — Polish existing demos and add combined IPAM+DNS workflow for SE-ready customer presentations
