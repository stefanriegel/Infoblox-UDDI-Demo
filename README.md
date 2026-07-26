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

### 3. NIOS-X Server on Proxmox
Clone a NIOS-X template on the Proxmox cluster and auto-join it to the Infoblox Portal.
- Workflow: `niosx-deployment.yml`
- Source: `NIOS-X-TEMPLATE` (VMID 1061) on `pve-fsn1-dc13` cluster
- Features: cloud-init join token via NoCloud seed ISO, VLAN-tagged SDN attach, auto node selection, resource pool placement

### 4. NIOS-X Server on AWS / Azure
Deploy NIOS-X from the vendor marketplace images and auto-join to the Infoblox Portal.
- Workflow: `niosx-cloud-deployment.yml`
- AWS: `ami-083f8f34b0e02be1a`, `c6a.xlarge`, eu-central-1 (Frankfurt)
- Azure: `infoblox-nios-x-vm` BYOL, `Standard_B4als_v2`, germanywestcentral (Frankfurt)
- Features: join token via cloud-init user-data/custom_data, self-contained VPC/VNet

### 5. Automated Cleanup
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
- Proxmox VE API token and a NIOS-X join token (for NIOS-X demo)

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

### NIOS-X Demo
1. Actions → "UDDI - NIOS-X on Proxmox" → Run workflow
2. Configure: VM name, target node (`auto` = first online), resource pool, VLAN tag, vCPU/RAM
3. Select `action: apply`
4. Terraform clones VMID 1061, uploads the cloud-init seed, and starts the VM
5. The server appears under Infrastructure → NIOS-X Servers in the Infoblox Portal

### NIOS-X Cloud Demo
1. Actions → "UDDI - NIOS-X on AWS / Azure" → Run workflow
2. Toggle AWS and/or Azure, pick instance size
3. Select `action: apply`
4. Each job summary reports instance ID, public/private IP and image used

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
cd live/demos/niosx-proxmox # NIOS-X on Proxmox demo
cd live/demos/niosx-aws   # NIOS-X on AWS demo
cd live/demos/niosx-azure # NIOS-X on Azure demo

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
│   │   ├── vpc-gcp/          # GCP VPC Terraform
│   │   ├── niosx-proxmox/    # NIOS-X on Proxmox Terraform
│   │   ├── niosx-aws/        # NIOS-X on AWS Terraform
│   │   └── niosx-azure/      # NIOS-X on Azure Terraform
│   └── docs/
│       ├── GITHUB_SECRETS.md # Secret setup guide
│       ├── README-NIOSX-DEMO.md # NIOS-X on Proxmox details
│       ├── README-NIOSX-CLOUD-DEMO.md # NIOS-X on AWS/Azure details
│       └── README-VPC-DEMO.md # VPC demo details
├── modules/
│   ├── cf_zone/              # Cloudflare integration
│   └── record_*/             # DNS record types
└── .github/workflows/
    ├── run-demo.yml          # DNS demo
    ├── vpc-deployment.yml    # Multi-cloud VPC
    ├── niosx-deployment.yml  # NIOS-X on Proxmox
    ├── niosx-cloud-deployment.yml # NIOS-X on AWS/Azure
    └── cleanup.yml           # Automated cleanup
```

## Documentation

- `live/docs/GITHUB_SECRETS.md` - Complete secret setup guide
- `live/docs/README-VPC-DEMO.md` - VPC deployment details
- `live/docs/README-NIOSX-DEMO.md` - NIOS-X on Proxmox details
- `live/docs/README-NIOSX-CLOUD-DEMO.md` - NIOS-X on AWS/Azure details
