# S02: Narrated Demo Output & Presentation Polish

**Goal:** Upgrade all 3 existing workflows (DNS, VPC, Cleanup) with professional narrated output, consistent Infoblox branding, timing metrics, and improved Mermaid diagrams. Establish the presentation conventions that S03 will apply to the combined workflow.
**Demo:** All existing workflows produce polished, step-by-step narrated job summaries that an SE can walk through live — with consistent branding, timing, and clear visual hierarchy.

## Must-Haves

- All 3 workflows have step-by-step narrated echo output with phase announcements and timing
- Job summaries share consistent branding: badge style, Mermaid node colors, section ordering
- VPC summary interpolation bug is fixed (single-quoted env var JSON)
- Mermaid diagrams are cleaner and consistent across workflows
- Timing metrics show duration for key phases (IPAM allocation, provisioning, verification)
- Cleanup workflow has a polished summary matching DNS/VPC presentation quality

## Proof Level

- This slice proves: contract (workflow YAML changes can be verified by reading the files; live run optional)
- Real runtime required: no (changes are presentation-layer; functional logic unchanged)
- Human/UAT required: yes (SE reviews presentation quality)

## Verification

- All 3 workflow YAML files are valid (no syntax errors)
- VPC summary step uses proper variable interpolation (not single-quoted `'${VAR}'`)
- Each workflow has: narrated echo output in at least 3 steps, timing capture, consistent badge/Mermaid style
- Job summary sections follow consistent ordering across all workflows

## Tasks

- [ ] **T01: Establish Presentation Conventions & Polish DNS Workflow** `est:1.5h`
  - Why: DNS workflow is already the most polished — it's the natural place to establish the presentation conventions that all other workflows will follow. Define the branding, narration, timing, and Mermaid patterns here first.
  - Files: `.github/workflows/run-demo.yml`
  - Do: (1) Define consistent conventions: badge colors (UDDI=#0066cc, Cloudflare=#f38020, Azure=#0078D4, AWS=#FF9900, GCP=#4285F4), Mermaid styling (consistent node shapes, connection styles, legend), section ordering (Header→Architecture→Config→Results→Verification→Provider→Value), narration format (`echo ""`; `echo "════════════════════════════════════════"` etc.), timing pattern (`START=$(date +%s)` ... `ELAPSED=$(($(date +%s) - START))`). (2) Apply these to the DNS workflow: add narrated phase announcements to each step, add timing to key phases (Terraform apply, DNS sync wait, verification), clean up Mermaid diagram consistency, tighten job summary sections. (3) Preserve all existing functional logic — this is presentation-only.
  - Verify: Workflow YAML valid, narration echo in ≥3 steps, timing capture in ≥2 steps, Mermaid renders (check syntax)
  - Done when: DNS workflow has full narration + timing + consistent branding, and the patterns are clear enough to replicate

- [ ] **T02: Polish VPC Workflow** `est:1.5h`
  - Why: VPC workflow has the weakest summary and a known interpolation bug. Apply the conventions established in T01.
  - Files: `.github/workflows/vpc-deployment.yml`
  - Do: (1) Fix VPC summary interpolation bug — the summary job uses `echo '${AWS_VERIFICATION}'` which doesn't interpolate env vars in single quotes; switch to double quotes or `cat <<EOF`. (2) Add narrated phase announcements to deployment steps (preflight, per-cloud provisioning, verification). (3) Add timing to per-cloud deployment and verification. (4) Improve job summary: add proper Mermaid diagram showing UDDI IPAM → multi-cloud flow with dynamic highlighting, consistent badges, consistent section ordering matching DNS workflow. (5) Ensure verify steps produce properly formatted output.
  - Verify: YAML valid, interpolation fixed (double-quote or heredoc), narration in ≥3 steps, Mermaid syntax correct
  - Done when: VPC workflow matches DNS workflow's presentation quality, interpolation bug fixed

- [ ] **T03: Polish Cleanup Workflow** `est:45m`
  - Why: Cleanup is part of the operational story — it should match the other workflows' presentation quality.
  - Files: `.github/workflows/cleanup.yml`
  - Do: (1) Add narrated phase announcements to cleanup steps (discovery phase, deletion phase per provider, IPAM cleanup). (2) Add timing to overall cleanup duration. (3) Improve job summary: add Mermaid diagram showing multi-zone/multi-cloud cleanup scope, consistent badges and branding, better table formatting for discovered/deleted resources. (4) Ensure DNS + VPC cleanup jobs both have matching summary style.
  - Verify: YAML valid, narration in ≥2 steps, summary has Mermaid diagram, consistent branding
  - Done when: Cleanup workflow presentation matches DNS/VPC quality, tells the operational lifecycle story

## Files Likely Touched

- `.github/workflows/run-demo.yml`
- `.github/workflows/vpc-deployment.yml`
- `.github/workflows/cleanup.yml`
