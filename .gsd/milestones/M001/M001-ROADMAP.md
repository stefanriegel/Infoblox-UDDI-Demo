# M001: Customer Demo Enhancement

**Vision:** Elevate the Infoblox UDDI demo repository from functional internal tooling to a polished, SE-ready customer demonstration suite. Add a combined IPAM+DNS workflow as the centerpiece, polish all existing workflows for professional presentation, and ensure the full suite feels production-grade.

## Success Criteria

- An SE can trigger the combined IPAM+DNS workflow and walk a customer through the output without verbal explanation
- All workflows produce consistent, professionally branded job summaries with Mermaid diagrams
- Workflow logs include step-by-step narration with timing that tells the UDDI value story
- The demo suite never feels like a toy or POC — error handling, verification, and operational patterns are visible

## Key Risks / Unknowns

- **Combined workflow state management** — Chaining IPAM → VPC → DNS in one workflow with proper state and error handling
- **GitHub job summary rendering** — Mermaid and markdown rendering has quirks; long summaries may hit limits
- **VPC summary interpolation bug** — Existing VPC summary step may have broken env var interpolation

## Proof Strategy

- Combined workflow complexity → retire in S01 by proving end-to-end IPAM+DNS flow works on real cloud infrastructure
- Presentation consistency → retire in S02 by producing all 4 workflow summaries with identical branding and narration style
- VPC summary bug → retire in S02 by fixing and verifying VPC workflow output

## Verification Classes

- Contract verification: workflows trigger without errors, job summaries render correctly
- Integration verification: combined workflow provisions real cloud resources and verifies DNS sync
- Operational verification: cleanup workflow handles combined demo resources
- UAT / human verification: SE reviews workflow output for demo readiness

## Milestone Definition of Done

This milestone is complete only when all are true:

- Combined IPAM+DNS workflow runs end-to-end on at least one cloud provider
- All 4 workflows (DNS, VPC, Combined, Cleanup) produce consistent, professional summaries
- Step-by-step narration visible in all workflow logs
- Cleanup workflow discovers and removes combined demo resources
- An SE can trigger any demo with zero prep and the output tells the story

## Requirement Coverage

- Covers: R001, R002, R003, R004, R005, R006, R007, R008, R009, R010, R011
- Partially covers: none
- Leaves for later: R012
- Orphan risks: none

## Slices

- [ ] **S01: Combined IPAM+DNS Workflow** `risk:high` `depends:[]`
  > After this: SE triggers one workflow that allocates a subnet from UDDI IPAM, provisions a VPC on AWS, creates a DNS A record in UDDI pointing to the VPC's CIDR, and verifies the DNS record synced to the cloud DNS provider — all proven with real cloud resources.

- [ ] **S02: Narrated Demo Output & Presentation Polish** `risk:medium` `depends:[]`
  > After this: All existing workflows (DNS, VPC, Cleanup) produce professional, step-by-step narrated job summaries with consistent Infoblox branding, timing metrics, and improved Mermaid diagrams — verified by reviewing actual workflow run output.

- [ ] **S03: SE Experience & Final Integration** `risk:low` `depends:[S01,S02]`
  > After this: All workflow inputs are SE-friendly with clear labels and defaults, cleanup handles combined demo resources, and the full demo suite is production-grade — verified by triggering each workflow and confirming the complete experience.

## Boundary Map

### S01 → S03

Produces:
- `.github/workflows/combined-demo.yml` — Complete combined IPAM+DNS workflow with job summary
- `live/demos/combined/` — Terraform configs for combined demo (IPAM allocation + VPC + DNS record)
- Resources tagged with `demo=true` and identifiable pattern for cleanup discovery

Consumes:
- nothing (first slice, uses existing UDDI/cloud infrastructure)

### S02 → S03

Produces:
- Updated `.github/workflows/run-demo.yml` — DNS workflow with narrated output and polished summary
- Updated `.github/workflows/vpc-deployment.yml` — VPC workflow with narrated output and polished summary
- Updated `.github/workflows/cleanup.yml` — Cleanup workflow with polished summary
- Established presentation patterns: branding constants, Mermaid style, narration format, timing approach

Consumes:
- nothing (parallel with S01, works on existing workflows)

### S01 + S02 → S03

S03 consumes:
- Combined workflow from S01 (applies SE-friendly input polish)
- Presentation patterns from S02 (ensures combined workflow matches the established style)
- Cleanup tag patterns from S01 (extends cleanup to handle combined demo resources)
