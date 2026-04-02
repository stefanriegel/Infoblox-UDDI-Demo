# S01: Combined IPAM+DNS Workflow

**Goal:** Build a single GitHub Actions workflow that demonstrates the full UDDI value proposition: allocate subnet from IPAM → provision AWS VPC → create DNS A record in UDDI → verify DNS sync to Route53.
**Demo:** SE triggers one workflow, customer sees UDDI allocate IP space, provision cloud networking, create DNS, and verify it all synced — in one run with a professional summary.

## Must-Haves

- Workflow runs end-to-end: IPAM allocation → VPC creation → DNS record creation → DNS verification
- Job summary shows the complete flow with architecture diagram, config table, and verification results
- All resources tagged `demo=true` for cleanup discovery
- `terraform validate` passes on the combined Terraform root
- Supports apply and destroy actions
- AWS is the default cloud provider (per D002)
- DNS uses UDDI-native sync model — record created in UDDI, verified on Route53 (per D001)

## Proof Level

- This slice proves: integration (real cloud resources provisioned and DNS verified)
- Real runtime required: yes (GitHub Actions with live cloud credentials)
- Human/UAT required: yes (SE reviews output quality)

## Verification

- `cd live/demos/combined && terraform init && terraform validate` passes
- Workflow YAML is valid (no syntax errors, all variable references resolve)
- Job summary generation logic covers: Mermaid diagram, config table, IPAM results, VPC results, DNS verification, value proposition
- Manual: trigger workflow on GitHub Actions and confirm end-to-end execution

## Tasks

- [ ] **T01: Combined Terraform Root** `est:1h`
  - Why: Need a single Terraform configuration that chains IPAM allocation → VPC provisioning → DNS record creation. This is the core infrastructure-as-code for the combined demo.
  - Files: `live/demos/combined/main.tf`, `live/demos/combined/variables.tf`
  - Do: Create `live/demos/combined/` directory with a Terraform root that: (1) uses `bloxone_ipam_next_available_subnets` to allocate from the AWS block, (2) creates `bloxone_ipam_subnet` to reserve it, (3) creates `aws_vpc` with the allocated CIDR, (4) creates `aws_internet_gateway`, (5) creates `bloxone_dns_a_record` in the `aws.gh.blox42.rocks.` zone pointing to a derived IP from the allocated CIDR. Follow patterns from existing `vpc-aws/main.tf` and `dns/main.tf`. Tag everything with `demo=true`, `automation=github-actions`, `workflow=combined`. Include proper outputs for all created resource IDs and CIDRs.
  - Verify: `terraform init && terraform validate` in the combined directory
  - Done when: Terraform config validates, has all 5 resource types, proper tags, and outputs

- [ ] **T02: Combined Workflow File** `est:1.5h`
  - Why: Need the GitHub Actions workflow that orchestrates the Terraform, runs DNS verification, and generates the job summary. This is the SE-facing interface.
  - Files: `.github/workflows/combined-demo.yml`
  - Do: Create workflow with `workflow_dispatch` inputs (network_name, record_name, subnet_size, action). Steps: checkout, setup terraform, cache state, terraform init/plan/apply, DNS verification via dig + Route53 API, narrated echo output at each phase with timing, and job summary generation with Mermaid diagram showing IPAM→VPC→DNS flow. Follow the DNS workflow pattern for verification steps and summary generation. Include destroy action support. Use cache key pattern `tfstate-combined-{network_name}` for state isolation.
  - Verify: YAML syntax valid, all input references resolve, step names are descriptive for SE narration
  - Done when: Workflow file is complete with all steps, narration, and summary generation

- [ ] **T03: Verify Combined Demo End-to-End** `est:30m`
  - Why: The Terraform and workflow need to work together. Verify the full config is coherent and ready for a real run.
  - Files: `live/demos/combined/main.tf`, `.github/workflows/combined-demo.yml`
  - Do: Review the complete workflow for: (1) all TF variable references match workflow env vars, (2) state cache path is correct, (3) DNS verification constructs the right FQDN from inputs, (4) job summary references correct step outputs, (5) destroy action properly cleans up. Fix any issues found.
  - Verify: Full review pass with no unresolved references, `terraform validate` still passes
  - Done when: Combined demo is internally consistent and ready for a live GitHub Actions run

## Files Likely Touched

- `live/demos/combined/main.tf`
- `live/demos/combined/variables.tf`
- `.github/workflows/combined-demo.yml`
