# M001: Customer Demo Enhancement

**Gathered:** 2026-04-02
**Status:** Ready for planning

## Project Description

Enhance the existing Infoblox UDDI demo repository to be SE-ready for live customer presentations. Polish existing workflow output, add a combined IPAM+DNS demo scenario, and ensure the entire suite feels production-grade.

## Why This Milestone

The demo repo works functionally but doesn't present well for live customer demos. SEs need to trigger workflows confidently in front of customers and have the output tell the UDDI value story without verbal explanation. The combined IPAM+DNS scenario — the strongest proof of UDDI's unique value — doesn't exist yet.

## User-Visible Outcome

### When this milestone is complete, the user can:

- Trigger a combined IPAM+DNS workflow that allocates a subnet, provisions a VPC, creates a DNS record, and verifies the full chain — all in one run
- Walk a customer through any workflow's output and have the story be self-evident from the logs and job summary
- Show consistent, professional, Infoblox-branded output across all demo workflows

### Entry point / environment

- Entry point: GitHub Actions `workflow_dispatch` UI
- Environment: GitHub Actions runners with Terraform 1.6.6
- Live dependencies involved: Infoblox UDDI API, AWS, Azure, GCP, Cloudflare

## Completion Class

- Contract complete means: all workflows can be triggered and produce expected outputs with professional formatting
- Integration complete means: combined workflow actually provisions real cloud resources and verifies DNS sync end-to-end
- Operational complete means: cleanup workflow handles resources from all demo types including the new combined workflow

## Final Integrated Acceptance

To call this milestone complete, we must prove:

- The combined IPAM+DNS workflow runs end-to-end on at least one cloud provider, producing a compelling unified summary
- All existing workflows (DNS, VPC, Cleanup) produce polished, narrated output consistent with the combined workflow's presentation quality
- An SE can trigger any demo with zero preparation and the output tells the UDDI value story

## Risks and Unknowns

- **Combined workflow complexity** — Chaining IPAM allocation → VPC creation → DNS record → verification in one workflow may hit state management or timing issues
- **VPC summary job interpolation** — The existing VPC summary step uses env var interpolation with jq that may not work correctly; needs investigation
- **GitHub job summary limits** — Very long summaries may hit GitHub's rendering limits; need to balance detail vs. length

## Existing Codebase / Prior Art

- `live/demos/dns/main.tf` — Working DNS Terraform, creates records in UDDI per zone
- `live/demos/vpc-aws/main.tf` — Working AWS VPC Terraform, uses UDDI IPAM next-available
- `live/demos/vpc-azure/main.tf` — Working Azure VNet Terraform with UDDI IPAM
- `live/demos/vpc-gcp/main.tf` — Working GCP VPC Terraform with UDDI IPAM
- `.github/workflows/run-demo.yml` — DNS workflow with multi-provider support and rich job summary (best current example)
- `.github/workflows/vpc-deployment.yml` — VPC workflow with parallel cloud deployment
- `.github/workflows/cleanup.yml` — Tag-based cleanup across all providers and zones
- `modules/` — Reusable TF modules for DNS records (not currently used by live demos)

> See `.gsd/DECISIONS.md` for all architectural and pattern decisions — it is an append-only register; read it during planning, append to it during execution.

## Relevant Requirements

- R001 — Combined IPAM+DNS workflow is the centerpiece new capability
- R002, R003, R004 — Narration, presentation, branding apply to all workflows
- R005 — Production-grade feel is the overarching quality bar
- R006, R007, R011 — Individual workflow polish tasks
- R008 — Timing metrics add demo impact
- R010 — SE-friendly inputs reduce demo friction

## Scope

### In Scope

- New combined IPAM+DNS workflow (Terraform + GitHub Actions)
- Job summary presentation improvements for all 4 workflows
- Step-by-step narrated log output in all workflows
- Consistent Infoblox/UDDI branding across summaries
- Timing metrics for key demo phases
- Mermaid diagram improvements
- Workflow input labels and defaults cleanup
- Cleanup workflow awareness of combined demo resources

### Out of Scope / Non-Goals

- Adding new cloud providers beyond the existing 4
- Changing the UDDI-native sync model (no dual-write)
- Production Terraform state backend (remains local/cached)
- VPC peering, transit gateways, or advanced networking scenarios
- Mobile/web UI for demos — GitHub Actions UI is the interface
- Documentation/README updates (deferred to R012)

## Technical Constraints

- Terraform 1.6.6 (pinned in workflows)
- BloxOne provider >= 1.5.0
- GitHub Actions job summary markdown rendering (supports Mermaid, badges, tables, but has quirks)
- All cloud credentials stored as GitHub Environment secrets (`dev` environment)
- Cleanup must use tag-based discovery (`demo=true`) — no hardcoded resource IDs

## Integration Points

- **Infoblox UDDI API** — DNS record creation, IPAM subnet allocation, tag-based queries
- **Cloudflare API** — DNS record verification (read-only)
- **Azure CLI** — VNet verification, DNS record verification
- **AWS CLI** — VPC verification, Route53 record verification
- **gcloud CLI** — VPC verification, Cloud DNS record verification
- **GitHub Actions cache** — Terraform state persistence between runs

## Open Questions

- **Which cloud provider for combined demo default?** — Leaning AWS since it has the simplest VPC model. Could offer multi-provider choice.
- **Module reuse** — The `modules/` directory has record modules not used by the live demos. Worth refactoring into modules or keep inline for demo clarity?
