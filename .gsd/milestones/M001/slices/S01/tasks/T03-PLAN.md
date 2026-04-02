---
estimated_steps: 5
estimated_files: 2
---

# T03: Verify Combined Demo End-to-End

**Slice:** S01 — Combined IPAM+DNS Workflow
**Milestone:** M001

## Description

Review the complete combined demo (Terraform + workflow) for internal consistency. Verify all variable references resolve, state caching is correct, DNS verification constructs the right FQDN, and destroy action works. Fix any issues found.

## Steps

1. Cross-reference workflow env vars with Terraform variable names — every `-var` in the plan/apply step must match a variable in `variables.tf`
2. Verify state cache path and key pattern isolates combined demo state from DNS and VPC demos
3. Trace DNS verification logic: FQDN should be `{record_name}.aws.gh.blox42.rocks.`, verify dig commands and Route53 query use correct zone and record name
4. Verify destroy step uses matching `-var` flags and doesn't leave orphaned resources
5. Final `terraform validate` pass to confirm no regressions from any fixes

## Must-Haves

- [ ] Every `-var` in the workflow matches a variable in `variables.tf`
- [ ] DNS FQDN construction matches what the Terraform `bloxone_dns_a_record` creates
- [ ] State cache key doesn't collide with existing DNS or VPC demo cache keys
- [ ] Destroy step has all the same `-var` flags as the apply step
- [ ] `terraform validate` passes

## Verification

- Manual review of cross-references between workflow and Terraform
- `cd live/demos/combined && terraform validate`

## Inputs

- T01 output: `live/demos/combined/main.tf`, `live/demos/combined/variables.tf`
- T02 output: `.github/workflows/combined-demo.yml`

## Expected Output

- Any fixes applied to `live/demos/combined/main.tf` or `.github/workflows/combined-demo.yml`
- Combined demo is internally consistent and ready for a live run
