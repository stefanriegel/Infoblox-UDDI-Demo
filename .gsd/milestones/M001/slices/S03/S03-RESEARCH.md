# S03: SE Experience & Final Integration — Research

**Date:** 2026-04-02
**Depth:** Light research — straightforward polish work applying established patterns from S01/S02 to known files.

## Summary

S03 is a polish and integration slice. The work breaks into three independent streams: (1) make all workflow inputs SE-friendly with clear labels/descriptions/defaults, (2) ensure the combined workflow matches S02's presentation patterns (missing badge, summary consistency), and (3) fix a tag gap so cleanup discovers combined demo resources. All patterns are established — this is application, not invention.

One real bug found: the combined demo's `aws_vpc` resource is missing `ManagedBy = "terraform"` and uses lowercase `demo` instead of `Demo` — the cleanup workflow's AWS VPC filter requires both `tag:ManagedBy,Values=terraform` AND `tag:Demo,Values=true` (case-sensitive). Combined demo VPCs will survive cleanup until this is fixed.

## Recommendation

Three parallel tasks, each touching independent files:

1. **Input polish across all 4 workflows** — Add/improve descriptions, reorder inputs logically, ensure defaults make sense for a live demo. This is the R010 task.
2. **Combined workflow presentation alignment** — Add the UDDI badge to `combined-demo.yml`, verify summary structure matches S02's HEADER/EOF/FOOTER pattern. This completes R004 consistency.
3. **Tag fix + cleanup verification** — Add `ManagedBy = "terraform"` and uppercase `Demo = "true"` to `live/demos/combined/main.tf` VPC/IGW resources so cleanup discovers them. Verify the IPAM subnet tags already work (they do — `cloud=aws` + `demo=true` matches the jq filter).

## Implementation Landscape

### Key Files

- `.github/workflows/combined-demo.yml` — Missing UDDI badge (0 occurrences vs 1 in each other workflow). Inputs need description polish (3 inputs: vpc_name, subnet_size, action).
- `.github/workflows/run-demo.yml` — Inputs already good. Minor polish: `record_value` description could be clearer for an SE.
- `.github/workflows/vpc-deployment.yml` — Inputs already have descriptions. `deploy_aws`/`deploy_azure`/`deploy_gcp` booleans default to `false` — consider whether at least one should default `true` for zero-config demo.
- `.github/workflows/cleanup.yml` — Single input `confirm` with `'Type "destroy" to confirm'`. Simple, correct, no change needed.
- `live/demos/combined/main.tf` — VPC resource (line ~tags) missing `ManagedBy = "terraform"` and `Demo = "true"` (uppercase). IGW resource same issue. IPAM subnet tags are correct.

### Current Input State

| Workflow | Inputs | Issues |
|----------|--------|--------|
| combined-demo | vpc_name, subnet_size, action | Descriptions are decent. Missing UDDI badge in summary. |
| run-demo (DNS) | dns_provider, record_name, record_type, record_value, ttl, action | `record_value` description is terse ("A/AAAA=IP, CNAME=target FQDN (with dot), TXT=content"). Could add example. |
| vpc-deployment | network_name, subnet_size, vpc_count, deploy_aws, deploy_azure, deploy_gcp, action | All 3 cloud booleans default false — SE must toggle at least one. Consider defaulting `deploy_aws: true`. |
| cleanup | confirm | Fine as-is. Safety gate works. |

### Tag Gap Detail

Cleanup's AWS VPC discovery filter (line 391):
```
--filters "Name=tag:ManagedBy,Values=terraform" "Name=tag:Demo,Values=true"
```

Combined demo's VPC tags (`live/demos/combined/main.tf`):
```hcl
tags = {
  Name       = var.vpc_name
  demo       = "true"          # lowercase — won't match "Demo"
  automation = "github-actions"
  # Missing: ManagedBy = "terraform", Demo = "true"
}
```

Fix: Add `ManagedBy = "terraform"` and change `demo` to `Demo` (or add both for belt-and-suspenders). Same for IGW resource.

### Build Order

All three tasks are independent — they touch different files (or different sections of the same file). Can run in parallel.

1. **Tag fix** (highest value — prevents orphaned resources, real bug)
2. **Input polish** (R010 — SE-facing improvement)
3. **Badge + presentation alignment** (consistency completion)

### Verification Approach

- **Tag fix:** `grep -i 'ManagedBy\|Demo' live/demos/combined/main.tf` confirms both tags present with correct casing. `terraform validate` in `live/demos/combined/` confirms no syntax errors.
- **Input polish:** YAML validation on all 4 workflows. Visual review of input descriptions.
- **Badge:** `grep -c 'Infoblox-Universal_DDI-0066cc' .github/workflows/combined-demo.yml` returns 1 (currently 0).
- **Cross-workflow consistency:** `grep -c 'Infoblox-Universal_DDI-0066cc' .github/workflows/*.yml` returns 4.
- **Full suite:** All 4 workflows pass YAML validation via `python3 -c "import yaml; yaml.safe_load(open(f))"`.

## Common Pitfalls

- **AWS tag case sensitivity** — AWS tags are case-sensitive. `demo=true` and `Demo=true` are different tags. The cleanup filter uses `Demo` (uppercase D). The combined demo must match exactly.
- **VPC deploy booleans** — If we default `deploy_aws: true` in the VPC workflow, existing automation that relies on the current `false` default would change behavior. Since this is a demo repo triggered manually, this is safe, but worth noting.

## Constraints

- Cannot change the cleanup workflow's tag filter pattern (established convention D003, used by existing vpc-aws/azure/gcp demos)
- Badge format must match exactly: `![Infoblox](https://img.shields.io/badge/Infoblox-Universal_DDI-0066cc)` per S02 pattern
