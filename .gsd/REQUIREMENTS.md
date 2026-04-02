# Requirements

This file is the explicit capability and coverage contract for the project.

## Active

### R001 — Combined IPAM+DNS demo workflow
- Class: core-capability
- Status: active
- Description: A single GitHub Actions workflow that demonstrates the full UDDI value: allocate subnet from IPAM → provision VPC on a cloud provider → create DNS record in UDDI → verify DNS sync to cloud DNS provider. End-to-end in one action.
- Why it matters: This is the "aha moment" for customers — UDDI as single control plane for both networking and DNS. No existing workflow shows this combined story.
- Source: user
- Primary owning slice: M001/S01
- Supporting slices: M001/S03
- Validation: unmapped
- Notes: Should support at least one cloud provider (AWS preferred as primary). DNS model is UDDI-native sync only.

### R002 — Step-by-step narrated workflow output
- Class: differentiator
- Status: active
- Description: Workflow logs include clear, step-by-step narration that an SE can walk through live during a demo. Each phase is announced, progress is visible, and the story flows naturally.
- Why it matters: SEs run this live in front of customers. The log output IS the demo — it needs to tell the story without verbal explanation.
- Source: user
- Primary owning slice: M001/S02
- Supporting slices: M001/S01
- Validation: unmapped
- Notes: Applies to all workflows, not just the new combined one.

### R003 — Professional job summary presentation
- Class: differentiator
- Status: active
- Description: GitHub Actions job summaries are clean, professional, and visually compelling. Tables are well-formatted, sections are logically organized, and the output looks production-grade.
- Why it matters: The job summary is what customers see after the run. It must look polished, not like a debug log.
- Source: user
- Primary owning slice: M001/S02
- Supporting slices: none
- Validation: unmapped
- Notes: Existing summaries are functional but inconsistent and verbose.

### R004 — Consistent branding across all workflows
- Class: quality-attribute
- Status: active
- Description: All workflow summaries share consistent Infoblox/UDDI branding, color scheme, badge style, section headers, and Mermaid diagram aesthetics.
- Why it matters: Inconsistent presentation undermines the "production-grade" message. A customer seeing different styles across demos questions the maturity.
- Source: user
- Primary owning slice: M001/S02
- Supporting slices: none
- Validation: unmapped
- Notes: Current DNS demo has more polish than VPC demo. Need to harmonize.

### R005 — Production-grade feel
- Class: quality-attribute
- Status: active
- Description: The demo should never feel like a toy or POC. Error handling is visible, verification is thorough, resource lifecycle is clean, and the automation patterns shown are adoptable in production.
- Why it matters: Customers need to see this as automation they could adopt, not a conference hack. This is the user's primary negative constraint.
- Source: user
- Primary owning slice: M001/S03
- Supporting slices: M001/S01, M001/S02
- Validation: unmapped
- Notes: Encompasses error handling, cleanup, verification depth, and overall operational maturity.

### R006 — DNS demo presentation polish
- Class: primary-user-loop
- Status: active
- Description: The existing DNS demo workflow gets improved job summary, narrated log output, better Mermaid diagrams, and consistent branding.
- Why it matters: This is the most-used demo. It works but needs to look as good as it functions.
- Source: user
- Primary owning slice: M001/S02
- Supporting slices: none
- Validation: unmapped
- Notes: Core Terraform is solid — this is presentation-layer only.

### R007 — VPC demo presentation polish
- Class: primary-user-loop
- Status: active
- Description: The existing VPC demo workflow gets improved job summary, narrated log output, better Mermaid diagrams, and consistent branding.
- Why it matters: VPC demo currently has a less polished summary than the DNS demo. Needs to match.
- Source: user
- Primary owning slice: M001/S02
- Supporting slices: none
- Validation: unmapped
- Notes: VPC summary job currently uses env var interpolation that may not work (jq in echo).

### R008 — Timing/performance metrics in output
- Class: differentiator
- Status: active
- Description: Workflow output includes timing for key phases (IPAM allocation, cloud provisioning, DNS sync, verification), showing how fast the automation is.
- Why it matters: Speed is a selling point. "Subnet allocated in 2s, VPC live in 45s, DNS verified globally in 10s" is compelling.
- Source: inferred
- Primary owning slice: M001/S02
- Supporting slices: M001/S01
- Validation: unmapped
- Notes: Should be unobtrusive — timing as annotation, not the focus.

### R009 — Mermaid diagram improvements
- Class: quality-attribute
- Status: active
- Description: Mermaid architecture diagrams in job summaries are cleaner, more visually consistent, and accurately reflect the flow for the specific demo run.
- Why it matters: The diagrams are the first thing customers scan. They need to be clear and professional.
- Source: inferred
- Primary owning slice: M001/S02
- Supporting slices: none
- Validation: unmapped
- Notes: Current DNS demo has dynamic Mermaid based on provider selection — good pattern to standardize.

### R010 — SE-friendly workflow inputs
- Class: launchability
- Status: active
- Description: All workflow_dispatch inputs have clear descriptions, sensible defaults, and are ordered logically so an SE can trigger a demo quickly and confidently.
- Why it matters: An SE in front of a customer can't fumble with confusing input fields. Speed and confidence matter.
- Source: inferred
- Primary owning slice: M001/S03
- Supporting slices: none
- Validation: unmapped
- Notes: Current inputs are functional but could be clearer (e.g., DNS value field description).

### R011 — Cleanup workflow presentation polish
- Class: operability
- Status: active
- Description: The cleanup workflow gets consistent branding and clear summary output showing what was found and cleaned across all providers.
- Why it matters: Cleanup is part of the operational story — showing automated lifecycle management is a selling point.
- Source: inferred
- Primary owning slice: M001/S02
- Supporting slices: none
- Validation: unmapped
- Notes: Lower priority than DNS/VPC/Combined polish but should match.

## Deferred

### R012 — README/docs updated for demo context
- Class: operability
- Status: deferred
- Description: Update README.md and docs to reflect the enhanced demo suite, including the new combined workflow and SE usage guide.
- Why it matters: New SEs need to understand how to use the demo suite.
- Source: inferred
- Primary owning slice: none
- Supporting slices: none
- Validation: unmapped
- Notes: Deferred — the workflows themselves should be self-explanatory. Docs can follow.

## Out of Scope

*None identified.*

## Traceability

| ID | Class | Status | Primary owner | Supporting | Proof |
|---|---|---|---|---|---|
| R001 | core-capability | active | M001/S01 | M001/S03 | unmapped |
| R002 | differentiator | active | M001/S02 | M001/S01 | unmapped |
| R003 | differentiator | active | M001/S02 | none | unmapped |
| R004 | quality-attribute | active | M001/S02 | none | unmapped |
| R005 | quality-attribute | active | M001/S03 | M001/S01, M001/S02 | unmapped |
| R006 | primary-user-loop | active | M001/S02 | none | unmapped |
| R007 | primary-user-loop | active | M001/S02 | none | unmapped |
| R008 | differentiator | active | M001/S02 | M001/S01 | unmapped |
| R009 | quality-attribute | active | M001/S02 | none | unmapped |
| R010 | launchability | active | M001/S03 | none | unmapped |
| R011 | operability | active | M001/S02 | none | unmapped |
| R012 | operability | deferred | none | none | unmapped |

## Coverage Summary

- Active requirements: 11
- Mapped to slices: 11
- Validated: 0
- Unmapped active requirements: 0
