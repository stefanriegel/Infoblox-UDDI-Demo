# S03: SE Experience & Final Integration

**Goal:** Polish all workflow inputs for SE use, extend cleanup to handle combined demo resources, align the combined workflow's presentation with S02's established conventions, and verify the full 4-workflow suite is consistent and production-grade.
**Demo:** An SE picks any workflow from the suite, triggers it with sensible defaults, and gets a professional, self-explanatory experience from input to summary — across all 4 workflows.

## Must-Haves

- All workflow inputs have clear descriptions, sensible defaults, and logical ordering
- Cleanup workflow discovers and removes combined demo resources (DNS records + VPC + IPAM subnets tagged `workflow=combined`)
- Combined workflow's job summary follows S02's established presentation conventions exactly
- All 4 workflows have consistent badge style, Mermaid aesthetics, section ordering, narration format
- No workflow has stale/confusing input descriptions

## Proof Level

- This slice proves: final-assembly (full suite consistency across all 4 workflows)
- Real runtime required: no (changes are input polish + cleanup extension + presentation alignment)
- Human/UAT required: yes (SE reviews complete suite)

## Integration Closure

- Upstream surfaces consumed: combined workflow from S01, presentation conventions from S02
- New wiring introduced: cleanup awareness of combined demo resources
- What remains before the milestone is truly usable end-to-end: nothing — this slice closes the loop

## Verification

- All 4 workflow YAML files valid
- Combined workflow job summary uses same branding/Mermaid patterns as DNS/VPC workflows
- Cleanup workflow scans for `workflow=combined` tagged resources
- All `workflow_dispatch` inputs have `description` fields that are clear and non-technical
- Default values are sensible for a quick demo trigger

## Tasks

- [ ] **T01: Polish All Workflow Inputs** `est:45m`
  - Why: SEs trigger these in front of customers — inputs must be clear, fast, and foolproof.
  - Files: `.github/workflows/run-demo.yml`, `.github/workflows/vpc-deployment.yml`, `.github/workflows/combined-demo.yml`, `.github/workflows/cleanup.yml`
  - Do: (1) Review every `workflow_dispatch` input across all 4 workflows. (2) Ensure descriptions are SE-friendly (not developer-oriented). E.g., "DNS hostname (e.g., www, api, app)" not "Record label (e.g. www)". (3) Ensure defaults allow a one-click demo — an SE should be able to hit "Run workflow" without changing anything and get a meaningful result. (4) Order inputs logically: most important first, action last. (5) For combined workflow: ensure input descriptions explain the full flow context.
  - Verify: Read all input descriptions — each makes sense to someone who isn't a Terraform developer
  - Done when: Every input across all 4 workflows is SE-friendly with sensible defaults

- [ ] **T02: Extend Cleanup for Combined Demo & Align Presentation** `est:1h`
  - Why: Combined demo creates resources that the current cleanup doesn't know about. Also need to ensure the combined workflow's summary matches S02's conventions.
  - Files: `.github/workflows/cleanup.yml`, `.github/workflows/combined-demo.yml`
  - Do: (1) In cleanup workflow: add the `aws.gh.blox42.rocks.` zone to the DNS cleanup scan if not already there (it is — verify). Ensure combined demo's VPC resources are found by the existing AWS VPC cleanup (they use `Demo=true` + `ManagedBy=terraform` tags — verify combined TF does the same). Ensure combined demo's IPAM subnets are found by existing IPAM cleanup (they use `demo=true` + `cloud=aws` tags — verify combined TF matches). (2) Review combined workflow's job summary: apply S02's badge style, Mermaid node colors, section ordering, narration format, and timing pattern. Ensure it's indistinguishable in quality from the polished DNS/VPC workflows. (3) Do a final consistency pass across all 4 workflow summaries — section headings, badge format, Mermaid style, narration echo format.
  - Verify: Cleanup logic covers combined resources (tag matching verified), combined summary matches S02 conventions
  - Done when: Cleanup handles combined demo, all 4 workflows are presentation-consistent

## Files Likely Touched

- `.github/workflows/run-demo.yml`
- `.github/workflows/vpc-deployment.yml`
- `.github/workflows/combined-demo.yml`
- `.github/workflows/cleanup.yml`
