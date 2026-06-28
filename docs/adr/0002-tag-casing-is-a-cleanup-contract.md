# Tag key casing is a cleanup contract, not style

Demo resources are tagged in two casings on purpose, and `.github/workflows/cleanup.yml` depends on the exact keys. Do **not** unify them.

## The contract

| Resource | Cleanup filter | Required tag keys |
| --- | --- | --- |
| UDDI IPAM subnet (`bloxone_ipam_subnet`) | `.tags.demo == "true"` + `.tags.cloud` | lowercase `demo`, `cloud` |
| UDDI DNS record (`bloxone_dns_*_record`) | `.tags.demo == "true"` | lowercase `demo` |
| Azure resource group | `az group list --tag demo=true` | lowercase `demo` |
| AWS VPC | `aws ec2 ... Name=tag:Demo,Values=true` + `Name=tag:ManagedBy,Values=terraform` | PascalCase `Demo`, `ManagedBy` |

## Why it looks wrong but isn't

A reader sees `Demo = "true"` on AWS resources and `demo = "true"` on UDDI/Azure resources and assumes drift. It is deliberate: the AWS CLI tag filter matches the literal key `Demo`, while the UDDI API and `az` filter on `demo`. Normalising to one casing would make cleanup unable to find half the resources, leaving orphaned VPCs or subnets.

## Consequences

- Changes to a resource's tags must keep the casing its cleanup path expects. If you add a new cloud demo, match the cleanup filter for that provider.
- Redundant lowercase `demo`/`automation` tags were removed from the combined demo's `aws_vpc`/`aws_internet_gateway`; the load-bearing PascalCase `Demo`/`ManagedBy` remain.
- A single shared `common_tags` map across the AWS and UDDI dialects is not possible without breaking this contract.
