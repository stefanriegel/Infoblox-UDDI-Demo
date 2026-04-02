# S01: Combined IPAM+DNS Workflow — UAT

**Milestone:** M001
**Written:** 2026-04-02

## UAT Type

- UAT mode: mixed (artifact-driven for static checks, live-runtime for end-to-end)
- Why this mode is sufficient: Terraform config and workflow YAML can be fully validated statically. Real cloud provisioning requires live credentials on GitHub Actions.

## Preconditions

- Repository checked out with `live/demos/combined/` and `.github/workflows/combined-demo.yml` present
- Terraform 1.6.6 installed locally for static validation
- For live tests: GitHub Actions `dev` environment configured with secrets: `BLOXONE_API_KEY`, `AWS_BLOCK_ID`, `IPAM_SPACE_ID`, `ROUTE53_HOSTED_ZONE_ID`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`
- `gh` CLI authenticated for workflow dispatch

## Smoke Test

Run `cd live/demos/combined && terraform init -backend=false && terraform validate` — must output `Success! The configuration is valid.`

## Test Cases

### 1. Terraform config validates cleanly

1. `cd live/demos/combined`
2. `terraform init -backend=false`
3. `terraform validate`
4. **Expected:** Exit code 0, output contains "The configuration is valid."

### 2. Workflow YAML is syntactically valid

1. `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/combined-demo.yml'))"`
2. **Expected:** Exit code 0, no output (no parse errors)

### 3. All workflow -var flags have matching Terraform variables

1. Extract variable names from `-var=` flags in `combined-demo.yml`
2. Extract variable names from `variable "..."` blocks in `variables.tf`
3. **Expected:** Every `-var` name (`bloxone_host`, `bloxone_api_key`, `vpc_name`, `subnet_size`, `aws_block_id`, `ipam_space_id`) exists in `variables.tf`

### 4. Variables with defaults are correctly omitted from workflow

1. Identify variables with defaults in `variables.tf`: `aws_region`, `record_name`, `zone_fqdn`
2. Check these do NOT appear in `-var=` flags in the workflow
3. **Expected:** None of the three appear as `-var` flags — Terraform uses their defaults

### 5. All step output references resolve

1. Extract all `steps.X.outputs.Y` references from the workflow
2. Verify each `X` matches a step `id:` in the same job
3. **Expected:** All references resolve — `steps.apply.outputs.*`, `steps.outputs.outputs.*`, `steps.dns_verify.outputs.*` all have matching step IDs

### 6. Live deploy creates all resources (requires credentials)

1. `gh workflow run combined-demo.yml -f vpc_name=uat-test -f subnet_size=24 -f action=deploy`
2. Wait for workflow to complete: `gh run list --workflow=combined-demo.yml --limit=1`
3. Open the run in GitHub UI and check the job summary
4. **Expected:**
   - Job summary contains Mermaid diagram with 3 stages (IPAM → VPC → DNS)
   - Configuration table shows vpc_name=uat-test, subnet_size=24
   - Results table shows VPC ID, CIDR, DNS FQDN, DNS record IP
   - Verification table shows ✅ for at least Google DNS and Route53 checks
   - Workflow logs show phase banners (🔷 Phase 1, 🔷 Phase 2, 🔷 Phase 3)

### 7. Live destroy tears down all resources (requires credentials)

1. After test case 6 completes successfully:
2. `gh workflow run combined-demo.yml -f vpc_name=uat-test -f subnet_size=24 -f action=destroy`
3. Wait for workflow to complete
4. **Expected:** Destroy job completes successfully, all resources removed, no orphaned resources in AWS or UDDI

### 8. Resource tagging is correct

1. During test case 6, after apply completes, check AWS console or CLI:
   - `aws ec2 describe-vpcs --filters "Name=tag:demo,Values=true"` should include the new VPC
   - VPC should also have `automation=github-actions` tag
2. **Expected:** Both `demo=true` and `automation=github-actions` tags present on VPC and IGW

## Edge Cases

### Empty vpc_name input

1. Attempt to trigger with empty vpc_name: `gh workflow run combined-demo.yml -f vpc_name="" -f subnet_size=24 -f action=deploy`
2. **Expected:** Workflow should fail at Terraform plan/apply stage since vpc_name is used in resource naming

### Subnet size out of range

1. Check `variables.tf` validation block for `subnet_size`
2. Attempt `terraform plan` with `subnet_size=8` (below minimum 16)
3. **Expected:** Terraform validation error: "Subnet size must be between 16 and 28"

### Deploy then deploy again (idempotency)

1. Run deploy twice with same vpc_name without destroying first
2. **Expected:** Second run should either update in-place or fail with a clear error about existing resources (depending on state cache hit)

## Failure Signals

- `terraform validate` returns errors → Terraform config is broken
- YAML parse fails → workflow file has syntax errors
- Step output references `steps.X.outputs.Y` where step ID `X` doesn't exist → workflow will fail at runtime with empty values
- DNS verification shows all ❌ → UDDI DNS sync not working or zone misconfigured
- Destroy job fails → orphaned cloud resources that need manual cleanup
- Job summary is empty or malformed → summary generation step has interpolation issues

## Requirements Proved By This UAT

- R001 — Test cases 6+7 prove the combined IPAM→VPC→DNS workflow works end-to-end (live run required)
- R002 — Test case 6 verifies phase narration is visible in logs (supporting role; S02 owns full narration polish)
- R008 — Test case 6 verifies timing is captured in the job summary (supporting role; S02 owns timing polish)

## Not Proven By This UAT

- R001 full validation requires a live GitHub Actions run (test cases 6-8)
- Presentation consistency across all workflows (R003, R004) — owned by S02
- SE-friendly input polish (R010) — owned by S03
- Cleanup workflow integration for combined resources (R011) — owned by S03
- Production-grade feel across the full suite (R005) — owned by S03

## Notes for Tester

- Test cases 1-5 can be run locally without any credentials — they validate structure only
- Test cases 6-8 require the `dev` environment secrets on GitHub Actions
- After test case 7 (destroy), verify no orphaned resources remain — check both AWS console and UDDI portal
- The DNS verification in test case 6 may show ❌ for some resolvers if DNS propagation is slow — wait 60s and re-check manually with `dig` if needed
- The literal zone name `aws.gh.blox42.rocks` in the job summary is intentional (avoids secret masking) — verify it matches the actual zone
