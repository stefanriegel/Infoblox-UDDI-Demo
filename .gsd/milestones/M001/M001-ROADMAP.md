# M001: Customer Demo Enhancement

**Vision:** Elevate the Infoblox UDDI demo repository from functional internal tooling to a polished, SE-ready customer demonstration suite. Add a combined IPAM+DNS workflow as the centerpiece, polish all existing workflows for professional presentation, and ensure the full suite feels production-grade.

## Success Criteria

- SE triggers the combined IPAM+DNS workflow and the job summary alone tells the full UDDI value story without verbal explanation
- All 4 workflows produce consistent, Infoblox-branded job summaries with Mermaid diagrams, timing metrics, and step-by-step narration in the logs
- Workflow logs read like a guided demo — each phase announced, progress visible, results clear
- The cleanup workflow discovers and removes resources from all demo types including the new combined workflow
- An SE with zero preparation can trigger any demo and have the output be customer-ready

## Key Risks / Unknowns

- **Combined workflow state management** — Chaining IPAM → VPC → DNS in one workflow with Terraform requires either multiple TF roots or a single combined root. State caching must isolate combined demo state from existing demos.
- **VPC summary interpolation** — The existing VPC summary job uses `echo '${VAR}'` with env vars containing JSON, which doesn't interpolate in single quotes. Needs fixing.

## Proof Strategy

- Combined workflow state management → retire in S01 by building and running the complete IPAM+VPC+DNS Terraform root with proper state isolation
- VPC summary interpolation → retire in S02 by fixing the summary step and verifying rendered output

## Verification Classes

- Contract verification: `terraform validate` on all TF configs, YAML lint on workflow files
- Integration verification: combined workflow provisions real AWS VPC + DNS record via UDDI (requires live run)
- Operational verification: cleanup workflow finds and removes combined demo resources
- UAT / human verification: SE reviews job summary output across all workflows for demo readiness

## Milestone Definition of Done

This milestone is complete only when all are true:

- Combined IPAM+DNS workflow has been triggered on GitHub Actions and produces end-to-end output with VPC + DNS verified
- DNS, VPC, and Cleanup workflows produce polished summaries matching the combined workflow's presentation quality
- Step-by-step narration with timing is present in all workflow logs
- Cleanup workflow discovers combined demo resources via `demo=true` tags
- All workflow inputs have clear descriptions and sensible defaults for SE use

## Requirement Coverage

- Covers: R001, R002, R003, R004, R005, R006, R007, R008, R009, R010, R011
- Partially covers: none
- Leaves for later: R012
- Orphan risks: none

## Slices

- [ ] **S01: Combined IPAM+DNS Workflow** `risk:high` `depends:[]`
  > After this: SE triggers one workflow that allocates a subnet from UDDI IPAM, provisions an AWS VPC, creates a DNS A record in UDDI for the VPC, and verifies DNS sync to Route53 — all proven with real cloud resources and a professional job summary.

- [ ] **S02: Narrated Demo Output & Presentation Polish** `risk:medium` `depends:[]`
  > After this: All 3 existing workflows (DNS, VPC, Cleanup) produce professional, step-by-step narrated job summaries with consistent Infoblox branding, timing metrics, and improved Mermaid diagrams — verified by reviewing the actual workflow YAML changes and their summary generation logic.

- [ ] **S03: SE Experience & Final Integration** `risk:low` `depends:[S01,S02]`
  > After this: All workflow inputs are SE-friendly, cleanup handles combined demo resources, the combined workflow matches S02's presentation patterns, and the full 4-workflow demo suite is consistent and production-grade.

## Boundary Map

### S01 → S03

Produces:
- `.github/workflows/combined-demo.yml` — Complete workflow with `workflow_dispatch` inputs, Terraform execution, DNS verification, and job summary
- `live/demos/combined/main.tf` — Terraform root combining IPAM next-available subnet, `aws_vpc`, and `bloxone_dns_a_record` in one apply
- `live/demos/combined/variables.tf` — Input variables for combined demo (network name, DNS record name, subnet size, cloud provider)
- Tag pattern: all resources tagged `demo=true`, `automation=github-actions`, `workflow=combined`
- Job summary structure: architecture Mermaid, config table, IPAM allocation details, VPC details, DNS verification, value proposition

Consumes:
- nothing (first slice — uses existing UDDI IPAM blocks, zones, and cloud credentials)

### S02 → S03

Produces:
- Updated `.github/workflows/run-demo.yml` — Narrated steps, consistent branding, timing, improved Mermaid
- Updated `.github/workflows/vpc-deployment.yml` — Fixed summary interpolation, narrated steps, consistent branding, timing
- Updated `.github/workflows/cleanup.yml` — Consistent branding, improved summary
- Established presentation conventions: badge style, Mermaid node colors, section ordering, narration echo format, timing capture pattern (`SECONDS` env var or `date +%s` deltas)

Consumes:
- nothing (works on existing workflows in parallel with S01)

### S01 + S02 → S03

S03 consumes from S01:
- Combined workflow file (applies input polish, ensures cleanup awareness)
- Combined demo tag patterns (extends cleanup to discover them)

S03 consumes from S02:
- Presentation conventions (applies to combined workflow's summary to ensure consistency)
- Narration patterns (ensures combined workflow log narration matches established style)
