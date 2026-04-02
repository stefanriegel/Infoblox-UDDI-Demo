---
estimated_steps: 9
estimated_files: 1
---

# T02: Combined Workflow File

**Slice:** S01 — Combined IPAM+DNS Workflow
**Milestone:** M001

## Description

Create the GitHub Actions workflow that orchestrates the combined Terraform demo, runs DNS verification, generates narrated log output, and produces a professional job summary. This is the SE-facing interface for the centerpiece demo.

## Steps

1. Create `.github/workflows/combined-demo.yml` with name `"UDDI - Combined IPAM + DNS"`
2. Add `workflow_dispatch` inputs: `network_name` (string, default `demo-app`), `record_name` (string, default `app`), `subnet_size` (choice: 24/26/28, default 24), `action` (choice: apply/destroy, default apply)
3. Add job `demo` with `runs-on: ubuntu-latest`, `environment: dev`, `working-directory: live/demos/combined`
4. Add env vars from secrets: `BLOXONE_HOST`, `BLOXONE_API_KEY`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`, `AWS_BLOCK_ID`, `IPAM_SPACE_ID`, `ROUTE53_HOSTED_ZONE_ID`
5. Add steps: checkout, setup terraform 1.6.6, cache state (key: `tfstate-combined-{network_name}`), terraform init, terraform validate
6. Add terraform plan step with all `-var` flags mapping inputs to TF variables, including `vpc_name={network_name}`, `record_name={record_name}`, etc.
7. Add terraform apply step (conditional on `action == apply`) with narrated echo output: phase announcements ("🔧 Phase 1: IPAM Allocation", "🏗️ Phase 2: VPC Provisioning", "📡 Phase 3: DNS Record Creation") and timing capture. Extract outputs to env vars after apply.
8. Add DNS verification step (conditional on apply): wait for sync, dig from 3 resolvers (8.8.8.8, 1.1.1.1, 9.9.9.9), query Route53 API for record confirmation. Add narration and timing.
9. Add job summary steps: header with badges, architecture Mermaid (IPAM→VPC→DNS→Verification flow), config table, IPAM allocation details, VPC details, DNS verification results, Route53 dashboard info, value proposition section. Add destroy step for destroy action.

## Must-Haves

- [ ] Workflow triggers via `workflow_dispatch` with 4 inputs
- [ ] Terraform plan/apply/destroy work with correct variable mapping
- [ ] DNS verification queries 3 public resolvers + Route53 API
- [ ] Narrated echo output at each phase with timing
- [ ] Job summary has: Mermaid diagram, config table, IPAM results, VPC results, DNS verification, value proposition
- [ ] State caching isolates combined demo from other demos
- [ ] Destroy action properly destroys resources

## Verification

- YAML syntax valid (no tabs, proper indentation)
- All `${{ inputs.* }}` and `${{ secrets.* }}` references are correct
- Step names read as a demo narration when viewed in GitHub Actions UI
- Job summary echo blocks produce valid markdown

## Inputs

- T01's Terraform root (`live/demos/combined/`) — variable names and outputs
- `.github/workflows/run-demo.yml` — Pattern for DNS verification and summary generation
- `.github/workflows/vpc-deployment.yml` — Pattern for VPC deployment with state caching
- D005: Step-by-step narration in logs + professional job summary

## Expected Output

- `.github/workflows/combined-demo.yml` — Complete workflow file ready for GitHub Actions
