---
estimated_steps: 6
estimated_files: 1
---

# T02: Create GitHub Actions workflow with narration, verification, and job summary

**Slice:** S01 — Combined IPAM+DNS Workflow
**Milestone:** M001

## Description

Create the GitHub Actions workflow that wires the T01 Terraform root into a triggerable, narrated demo. The workflow must tell the UDDI story through its logs (step-by-step narration with timing) and its job summary (Mermaid diagram, resource details, verification results). It also handles the destroy path for cleanup. Follow the patterns established in `run-demo.yml` (DNS demo) for verification and summary generation.

**Skill:** Load `github-workflows` skill for workflow syntax validation.

## Steps

1. **Create `.github/workflows/combined-demo.yml`** with workflow_dispatch inputs:
   - `vpc_name`: string, default "uddi-combined-demo", description for SE
   - `subnet_size`: choice [24, 25, 26, 27, 28], default "24"
   - `action`: choice [deploy, destroy], default "deploy"
   - Use `dev` environment for secrets access

2. **Build the deploy job** with narrated phases:
   - **Setup**: checkout, setup terraform 1.6.6, restore cache (key: `tfstate-combined-${{ inputs.vpc_name }}`), terraform init
   - **Phase 1 — IPAM Allocation**: echo narration banner, capture `START_IPAM=$(date +%s)`, terraform plan (show what will be allocated), terraform apply, capture timing `IPAM_DURATION`
   - Actually: use a single `terraform apply` but narrate the phases by extracting outputs after apply. The Terraform apply is atomic — you can't apply IPAM separately. Instead: narrate the plan output to highlight each phase, then apply once, then extract outputs and narrate results per phase.
   - **Extract outputs**: `terraform output -json` → parse `vpc_id`, `vpc_cidr`, `dns_record_fqdn`, `dns_record_value`, `ipam_subnet_address` into step outputs and env vars
   - **Phase narration**: After apply, echo phase-by-phase results with timing
   - **DNS Verification**: sleep 15 (UDDI→Route53 sync), then:
     - `dig +short $FQDN @8.8.8.8`, `@1.1.1.1`, `@9.9.9.9` — capture results
     - `aws route53 list-resource-record-sets --hosted-zone-id ${{ secrets.ROUTE53_HOSTED_ZONE_ID }}` filtered for the FQDN — capture result
   - **Save cache**: save terraform state with same cache key

3. **Build the destroy job** (conditional on `inputs.action == 'destroy'`):
   - Checkout, setup terraform, restore cache, init, destroy with all variables, save empty cache

4. **Generate job summary** (deploy path only):
   - Mermaid diagram: 3-stage flow `IPAM Allocation --> VPC Provisioning --> DNS Record + Verification`
   - Config table: VPC name, subnet size, region, zone FQDN
   - Results table: IPAM subnet address, VPC ID, VPC CIDR, DNS FQDN, DNS record IP
   - Verification table: dig results per resolver (✅/❌), Route53 API result (✅/❌)
   - Timing summary: total duration, per-phase if feasible
   - Value proposition footer (same style as `run-demo.yml`)
   - Write to `$GITHUB_STEP_SUMMARY`

5. **Cross-reference audit**:
   - Every `-var="X=${{ ... }}"` in terraform commands must match a variable name in `live/demos/combined/variables.tf`
   - Every `${{ steps.X.outputs.Y }}` must have a corresponding step with id `X` that sets output `Y`
   - Secrets used: `BLOXONE_API_KEY`, `AWS_BLOCK_ID`, `IPAM_SPACE_ID`, `ROUTE53_HOSTED_ZONE_ID` — all from `dev` environment
   - Use literal zone name `aws.gh.blox42.rocks` in summary output (not secret references) to avoid GitHub's automatic masking

6. **Validate**: Parse YAML with python, review for syntax errors.

## Must-Haves

- [ ] `workflow_dispatch` with `vpc_name`, `subnet_size` (choice), `action` (choice: deploy/destroy) inputs
- [ ] Terraform 1.6.6 pinned via `hashicorp/setup-terraform@v3`
- [ ] State cache with unique key `tfstate-combined-${{ inputs.vpc_name }}` (D004)
- [ ] All `-var` flags map to real variables in `live/demos/combined/variables.tf`
- [ ] DNS verification: dig against 3 resolvers + Route53 API check after 15s sleep
- [ ] Job summary with Mermaid 3-stage diagram, config table, results table, verification table
- [ ] Phase timing captured with `date +%s` and displayed in narration/summary
- [ ] Destroy path functional: restores cache, runs `terraform destroy`, saves cache
- [ ] Step-by-step echo narration visible in logs for each phase (R002)
- [ ] Uses `dev` environment for secrets

## Verification

- `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/combined-demo.yml'))"` exits 0
- Cross-reference: extract all `-var="X=` from workflow, extract all `variable "X"` from variables.tf — sets must match
- Cross-reference: all `${{ steps.*.outputs.* }}` references resolve to defined step IDs
- Workflow `on.workflow_dispatch.inputs` has exactly 3 inputs: `vpc_name`, `subnet_size`, `action`

## Inputs

- `live/demos/combined/main.tf` — T01 output. Need to know: exact variable names, output names, provider requirements.
- `live/demos/combined/variables.tf` — T01 output. Need to know: variable names, types, defaults for `-var` flag construction.
- `.github/workflows/run-demo.yml` — Gold standard for: DNS verification (dig + Route53 API), job summary format (Mermaid + tables), cache pattern, terraform setup.
- `.github/workflows/vpc-deployment.yml` — Reference for: VPC-specific input patterns, preflight validation.
- Decision D001: UDDI-native sync only — verify sync, don't create directly in Route53.
- Decision D004: Local state with cache, key includes workflow+name for isolation.
- Decision D005: Step-by-step narration in logs + professional job summary.

## Expected Output

- `.github/workflows/combined-demo.yml` — Complete workflow file ready for live execution on GitHub Actions, with deploy and destroy paths, narrated logging, DNS verification, and professional job summary
