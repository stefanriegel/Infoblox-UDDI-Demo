---
estimated_steps: 5
estimated_files: 5
---

# T02: Polish workflow inputs for SE experience and add cross-suite verification

**Slice:** S03 — SE Experience & Final Integration
**Milestone:** M001

## Description

R010 requires all workflow_dispatch inputs to be SE-friendly — clear descriptions, sensible defaults, logical ordering. Currently some inputs have terse descriptions (DNS `record_value`), some have all-false defaults requiring manual toggling (VPC cloud booleans), and none have been reviewed holistically for SE experience. This task polishes all 4 workflows' inputs and creates a verification script that ensures cross-suite consistency is maintained.

**Relevant skill:** `github-workflows` (for workflow YAML editing)

## Steps

1. **Polish `combined-demo.yml` inputs:**
   - `vpc_name`: Description is adequate. Keep as-is.
   - `subnet_size`: Add a note like "Smaller number = larger subnet (e.g., /24 = 256 IPs)" to the description for SEs unfamiliar with CIDR.
   - `action`: Adequate. Keep as-is.

2. **Polish `run-demo.yml` (DNS) inputs:**
   - `record_value`: Current description is terse ("A/AAAA=IP, CNAME=target FQDN (with dot), TXT=content"). Expand with a concrete example like "IP address for A records (e.g., 10.0.1.1), target FQDN with trailing dot for CNAME (e.g., example.com.), or text content for TXT".
   - Review all other inputs — `dns_provider`, `record_name`, `record_type`, `ttl`, `action` — and improve descriptions if unclear. Most are already good.

3. **Polish `vpc-deployment.yml` inputs:**
   - Change `deploy_aws` default from `false` to `true` so an SE can trigger the workflow with zero toggles and get a working demo. AWS is the simplest cloud and the primary demo target (per D002).
   - Improve boolean descriptions: instead of just "Deploy to AWS", use "Deploy VPC to AWS (recommended for first demo)" for `deploy_aws`.
   - Review `network_name`, `subnet_size`, `vpc_count`, `action` descriptions.

4. **Review `cleanup.yml` input:**
   - Single `confirm` input with safety gate. Already good — no changes needed unless description could be clearer.

5. **Create `scripts/verify-s03.sh`** — a verification script that checks the entire demo suite:
   ```bash
   #!/usr/bin/env bash
   set -euo pipefail
   PASS=0; FAIL=0
   
   # Check 1: All 4 workflow YAMLs parse
   for f in .github/workflows/cleanup.yml .github/workflows/combined-demo.yml .github/workflows/run-demo.yml .github/workflows/vpc-deployment.yml; do
     python3 -c "import yaml; yaml.safe_load(open('$f'))" && ((PASS++)) || ((FAIL++))
   done
   
   # Check 2: Badge in all 4 workflows
   count=$(grep -l 'Infoblox-Universal_DDI-0066cc' .github/workflows/*.yml | wc -l)
   [ "$count" -ge 4 ] && ((PASS++)) || ((FAIL++))
   
   # Check 3: Combined demo tags correct
   grep -q 'ManagedBy' live/demos/combined/main.tf && ((PASS++)) || ((FAIL++))
   grep -q 'Demo.*"true"' live/demos/combined/main.tf && ((PASS++)) || ((FAIL++))
   
   # Check 4: Terraform validates
   (cd live/demos/combined && terraform init -backend=false -no-color >/dev/null 2>&1 && terraform validate -no-color >/dev/null 2>&1) && ((PASS++)) || ((FAIL++))
   
   # Check 5: Narration present in all workflows
   for f in .github/workflows/run-demo.yml .github/workflows/vpc-deployment.yml .github/workflows/cleanup.yml .github/workflows/combined-demo.yml; do
     grep -q '╔══' "$f" && ((PASS++)) || ((FAIL++))
   done
   
   echo "Results: $PASS passed, $FAIL failed"
   [ "$FAIL" -eq 0 ]
   ```
   Run the script and fix any issues found.

## Must-Haves

- [ ] DNS `record_value` input has an expanded, SE-friendly description with examples
- [ ] VPC `deploy_aws` defaults to `true` for zero-config demo experience
- [ ] VPC cloud boolean descriptions clarify which is recommended
- [ ] `scripts/verify-s03.sh` exists and passes all checks
- [ ] All 4 workflow YAML files remain valid after changes

## Verification

- `bash scripts/verify-s03.sh` passes with 0 failures
- `grep 'default:' .github/workflows/vpc-deployment.yml` shows `deploy_aws` defaults to `true`
- `grep -A2 'record_value' .github/workflows/run-demo.yml` shows expanded description
- All 4 workflows parse: `for f in .github/workflows/*.yml; do python3 -c "import yaml; yaml.safe_load(open('$f'))"; done`

## Inputs

- `.github/workflows/combined-demo.yml` — From T01, now has badge. Inputs: vpc_name, subnet_size, action.
- `.github/workflows/run-demo.yml` — From S02, has narration/branding. 6 inputs need review.
- `.github/workflows/vpc-deployment.yml` — From S02, has narration/branding. 7 inputs, cloud booleans all default false.
- `.github/workflows/cleanup.yml` — From S02, has narration/branding. 1 input (confirm), likely no change needed.
- S02 Forward Intelligence: The presentation pattern is badge → title → Mermaid → tables → value prop → footer.
- D002: AWS is default/primary cloud for demos.

## Expected Output

- `.github/workflows/combined-demo.yml` — Improved input descriptions
- `.github/workflows/run-demo.yml` — Expanded `record_value` description with examples
- `.github/workflows/vpc-deployment.yml` — `deploy_aws` defaults to `true`, improved boolean descriptions
- `.github/workflows/cleanup.yml` — Minor description improvements if warranted, otherwise unchanged
- `scripts/verify-s03.sh` — Cross-suite verification script that validates consistency
