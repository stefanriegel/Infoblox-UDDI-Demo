# S03: SE Experience & Final Integration — UAT

**Milestone:** M001
**Written:** 2026-04-02

## UAT Type

- UAT mode: mixed (artifact-driven + human-experience)
- Why this mode is sufficient: Static checks cover tag correctness, YAML validity, badge presence, and input descriptions. Live GitHub Actions runs are needed to confirm visual rendering and SE experience.

## Preconditions

- GitHub repository access with workflow_dispatch permissions
- AWS credentials configured in repository secrets (for combined and VPC demos)
- Infoblox BloxOne API key configured in repository secrets
- Cloudflare API token configured (for DNS demo default provider)
- `scripts/verify-s03.sh` exists and is executable

## Smoke Test

Run `bash scripts/verify-s03.sh` from the repository root — all 15 checks must pass. This confirms the suite is structurally consistent before live testing.

## Test Cases

### 1. Cross-suite verification script

1. Clone the repository or pull latest changes
2. Run `bash scripts/verify-s03.sh`
3. **Expected:** 15 passed, 0 failed. Output shows green checkmarks for YAML parsing, UDDI branding, combined demo tags, Terraform validation, narration boxes, and SE-friendly inputs.

### 2. DNS demo — zero-config trigger

1. Go to Actions → "DNS Record Demo" → Run workflow
2. Leave all inputs at their defaults (do not change anything)
3. Click "Run workflow"
4. **Expected:** Workflow runs successfully. Job summary shows UDDI badge at top, Mermaid architecture diagram, narrated step output with timing, and a professional results table. Default creates an A record on Cloudflare zone.

### 3. VPC demo — zero-config trigger

1. Go to Actions → "VPC Deployment Demo" → Run workflow
2. Leave all inputs at their defaults
3. Verify `deploy_aws` is pre-checked (default: true)
4. Click "Run workflow"
5. **Expected:** Workflow runs successfully with AWS VPC provisioned. Job summary shows UDDI badge, Mermaid diagram, IPAM allocation narration, and VPC details table. No need to manually select a cloud provider.

### 4. Combined demo — zero-config trigger

1. Go to Actions → "Combined IPAM + DNS Demo" → Run workflow
2. Leave all inputs at defaults
3. Click "Run workflow"
4. **Expected:** Workflow runs end-to-end: IPAM allocation → VPC provisioning → DNS record creation → DNS verification. Job summary shows UDDI badge, phased Mermaid diagram, and narrated output for each phase with timing.

### 5. Cleanup discovers combined demo resources

1. After test case 4 completes (combined demo VPC exists), go to Actions → "Demo Cleanup"
2. Set `confirm` to any value other than "destroy" (or leave blank) for dry-run behavior, OR set `dry_run: true` if available
3. Run the workflow
4. **Expected:** Cleanup discovery output lists the combined demo VPC and IGW. Resources tagged `Demo=true` and `ManagedBy=terraform` from the combined demo appear in the discovery list.

### 6. Cleanup executes successfully

1. Go to Actions → "Demo Cleanup" → Run workflow
2. Type `destroy` in the confirm field
3. Run the workflow
4. **Expected:** All demo resources (DNS records, VPCs, IGWs) from previous test cases are cleaned up. Job summary shows UDDI badge, discovery results, and cleanup confirmation.

### 7. Input descriptions are SE-friendly

1. Go to Actions → "DNS Record Demo" → Run workflow (but don't run it)
2. Inspect the `record_value` input description
3. **Expected:** Description includes concrete examples like "10.0.1.1" for A records
4. Go to Actions → "VPC Deployment Demo" → Run workflow
5. Inspect `deploy_aws` — should show as checked by default with "(recommended for first demo)" in description
6. Inspect `subnet_size` — should explain CIDR notation ("smaller number = larger subnet")
7. **Expected:** All inputs are self-explanatory; an SE unfamiliar with the repo can understand every field without documentation.

## Edge Cases

### Combined demo with non-default subnet size

1. Trigger combined demo with `subnet_size` set to `24` instead of default
2. **Expected:** IPAM allocates a /24 subnet, VPC uses the allocated CIDR, DNS record points to correct address. Job summary reflects the custom size.

### Cleanup with no demo resources deployed

1. Ensure no demo resources exist (run cleanup first)
2. Trigger cleanup with `confirm: destroy`
3. **Expected:** Cleanup runs without error, summary shows 0 resources discovered, no errors thrown.

### DNS demo with explicit record value

1. Trigger DNS demo with `record_value` set to a specific IP (e.g., `192.168.1.100`)
2. **Expected:** Record created with the specified value. Narration reflects the custom value.

## Failure Signals

- Any workflow fails to trigger or errors before producing a job summary → YAML syntax issue
- Job summary missing UDDI badge → badge heredoc block was removed or malformed
- Cleanup workflow shows 0 VPCs discovered after combined demo → tags in `main.tf` are wrong (check case: `Demo` vs `demo`)
- VPC workflow asks user to select a provider (no default) → `deploy_aws` default reverted to `false`
- Terraform plan errors in combined demo → `main.tf` tag syntax broken or provider config issue
- `verify-s03.sh` reports failures → cross-suite consistency broken, fix before live testing

## Requirements Proved By This UAT

- R001 — Test case 4 proves combined IPAM+DNS workflow runs end-to-end (live validation)
- R004 — Test cases 2-6 visually confirm consistent UDDI branding across all 4 workflows
- R005 — Test cases 5-6 prove cleanup handles combined demo resources (production-grade lifecycle)
- R010 — Test case 7 proves SE-friendly inputs with examples and defaults

## Not Proven By This UAT

- R012 (README/docs) — deferred, not in scope for M001
- Multi-cloud combined demo (Azure/GCP) — only AWS path tested
- Concurrent demo runs — no test for parallel workflow execution conflicts
- Session/token expiry behavior — long-running scenarios not covered

## Notes for Tester

- Run test cases 2-4 first to create resources, then test cases 5-6 to verify cleanup discovers and removes them.
- The combined demo (test case 4) takes the longest — expect 3-5 minutes for full IPAM+VPC+DNS flow.
- Job summaries are viewable in the Actions run's "Summary" tab, not in the log output.
- If any workflow fails due to cloud provider quota or transient API errors, retry once before reporting as a failure.
- The `verify-s03.sh` script (test case 1) is the quickest pre-flight check — run it before any live testing.
