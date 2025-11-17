# Infoblox Universal DDI Demos

Demonstrations of Infoblox UDDI as centralized management platform for DNS and IPAM across multiple cloud providers. Automated with Terraform (BloxOne provider) and GitHub Actions.

## Available Demos

### 1. DNS Management + Cloudflare Sync
Central DNS record management in UDDI with automatic synchronization to Cloudflare.
- Workflow: `run-demo.yml`
- Record types: A, AAAA, TXT, CNAME
- Features: Multi-resolver verification, Cloudflare Orange Cloud support

### 2. Multi-Cloud VPC/VNet Provisioning
UDDI as IPAM source for automatic subnet allocation across AWS, Azure, and GCP.
- Workflow: `vpc-deployment.yml`
- Providers: AWS VPC, Azure VNet, GCP VPC
- Features: Next-available subnet allocation, multi-cloud deployment (1-3 networks per provider)

### 3. Automated Cleanup
Scheduled and manual cleanup of demo resources.
- Workflow: `cleanup.yml`
- Runs: Daily at 00:00 GMT+2 or manual trigger
- Cleanup: DNS records, VPCs/VNets, IPAM subnets via native cloud CLIs

## Architecture

```
GitHub Actions (UI) --> Terraform --> Infoblox UDDI --> Cloud Providers
                                           |              (AWS/Azure/GCP)
                                           |
                                           +--> Cloudflare DNS
```

## Requirements

- GitHub Environment `dev` with secrets configured (see `live/docs/GITHUB_SECRETS.md`)
- Terraform 1.6.6 (provided by GitHub Actions)
- UDDI API access
- Cloud provider credentials (AWS, Azure, GCP)
- Cloudflare account (for DNS demo)

## Quick Start

### DNS Demo
1. Actions → "UDDI - DNS Demo" → Run workflow
2. Configure: zone, record name, type, value, TTL
3. Select `action: apply`
4. View job summary with verification results

### VPC Demo
1. Actions → "UDDI - VPC Deployment" → Run workflow
2. Select cloud providers (AWS/Azure/GCP)
3. Configure: network name, subnet size (/24-/28), regions
4. Choose VPC count (1-3 per provider)
5. UDDI allocates subnets from predefined blocks automatically

### Cleanup
1. Actions → "UDDI - Automated Cleanup" → Run workflow
2. Enter `destroy` to confirm
3. Deletes all demo-tagged resources across all clouds

## Local Usage

```bash
cd live/demos/dns         # DNS demo
cd live/demos/vpc-aws     # AWS VPC demo
cd live/demos/vpc-azure   # Azure VNet demo
cd live/demos/vpc-gcp     # GCP VPC demo

terraform init
terraform plan -var="bloxone_api_key=$BLOXONE_API_KEY" ...
terraform apply -auto-approve
```

## Key Features

- Tag-based resource management (`demo=true`)
- State-independent cleanup using native cloud CLIs
- Multi-resolver DNS verification (Google, Cloudflare, Quad9)
- Terraform state caching via GitHub Actions
- Professional job summaries with architecture diagrams

## Security

- All credentials stored as GitHub Secrets
- Environment protection rules supported
- No secrets in repository files

## Project Structure

```
.
├── live/
│   ├── demos/
│   │   ├── dns/              # DNS demo Terraform
│   │   ├── vpc-aws/          # AWS VPC Terraform
│   │   ├── vpc-azure/        # Azure VNet Terraform
│   │   └── vpc-gcp/          # GCP VPC Terraform
│   └── docs/
│       ├── GITHUB_SECRETS.md # Secret setup guide
│       └── README-VPC-DEMO.md # VPC demo details
├── modules/
│   ├── cf_zone/              # Cloudflare integration
│   └── record_*/             # DNS record types
└── .github/workflows/
    ├── run-demo.yml          # DNS demo
    ├── vpc-deployment.yml    # Multi-cloud VPC
    └── cleanup.yml           # Automated cleanup
```

## Documentation

- `live/docs/GITHUB_SECRETS.md` - Complete secret setup guide
- `live/docs/README-VPC-DEMO.md` - VPC deployment details
