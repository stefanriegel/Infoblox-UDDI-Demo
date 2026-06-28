# Cloud demos stay standalone — no cross-cloud network module

The `allocated_subnet` module is the deliberate shared seam under the AWS, Azure, and GCP demos: it owns the UDDI IPAM allocation that is genuinely identical across clouds. We will **not** push the deepening further by unifying the per-cloud network resources (`aws_vpc`+`igw`, `azurerm_*`, `google_compute_*`) behind one interface.

## Why

- The three network shapes differ genuinely. A single cross-cloud interface would be **shallow** — nearly as complex as the implementations it wraps — and would leak each provider's specifics back through the seam. Depth is leverage at the interface; there is none to gain here.
- Each demo is a **standalone teaching artifact**. Its real interface is pedagogical: a reader follows one file top-to-bottom as "UDDI drives cloud X". Modularizing the cloud half trades that readability for indirection the demo does not need.
- The remaining repetition (`provider "bloxone"`, `terraform {}` / `required_providers`, shared variables) is irreducible — Terraform requires provider configuration at the root module. Removing it would mean Terragrunt or codegen, a larger cost than the duplication it eliminates.

## Consequences

- The AWS VPC construction stays duplicated between `live/demos/vpc-aws` and `live/demos/combined`. This was considered for an `aws_network` module (two callers = a real seam) and deliberately declined to keep both demos self-contained. Revisit only if a third AWS caller appears.
- Future architecture reviews should not re-suggest "DRY up the cloud demos". The shared seam stops at subnet allocation by design.
