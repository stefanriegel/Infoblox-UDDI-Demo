# NIOS-X on AWS and Azure Demo

Deploys a NIOS-X server from the vendor marketplace image on AWS or Azure
(both Frankfurt), passes the join token through cloud-init, and lets the server
register itself with the Infoblox Portal.

- Terraform: `live/demos/niosx-aws/`, `live/demos/niosx-azure/`
- Workflow: `.github/workflows/niosx-cloud-deployment.yml`
- Proxmox equivalent: `README-NIOSX-DEMO.md`

## The payload is the same everywhere

All three NIOS-X demos hand cloud-init the same document. Only the delivery
channel differs:

| Platform | Delivery |
|---|---|
| Proxmox | NoCloud seed ISO on a CD-ROM (no native user-data channel) |
| AWS | `user_data` on the instance |
| Azure | `custom_data` on the VM, base64-encoded |

```yaml
#cloud-config
host_setup:
  jointoken: <NIOSX_JOIN_TOKEN>
  tags:
    - demo=true
    - automation=github-actions
    - hostname=<name>
```

## Sizing

Infoblox's floor for a virtual NIOS-X server is **3 cores / 4 GB / 64 GB**
(smallest form factor, 5 kQPS). Both defaults clear it at 4 vCPU / 8 GB, which
matches the Proxmox demo.

### AWS — eu-central-1

The AWS guide states *"AWS Xen-based instances are not supported (because they
create interface names with capital letters)"*, so the type must be Nitro-based.
That rules out the M4/C4/T2/R4 families the older docs list.

| instance | vCPU / RAM | USD/mo |
|---|---|---|
| **c6a.xlarge** (default) | 4 / 8 | 127.46 |
| c6i.xlarge | 4 / 8 | 141.62 |
| m6a.xlarge | 4 / 16 | 151.11 |

`t3a.xlarge` is marginally cheaper at $126.14/mo but is burstable; the $1.32
difference is not worth credit-based CPU. Two-vCPU types such as `t3a.large`
($63/mo) sit below the 3-core floor and are not supported.

### Azure — germanywestcentral (Frankfurt)

Size choice here is constrained by **quota**, not just price. On this
subscription the `Basv2`, `DLSv5`, `DSv5` and `DASv5` families all have a core
limit of **0** in GermanyWestCentral, so the cheapest sizes on paper cannot be
deployed at all. `BS`, `FSv2` and `DSv3` have a limit of 10.

| size | vCPU / RAM | quota | USD/mo |
|---|---|---|---|
| Standard_B4als_v2 | 4 / 8 | 0 — unusable | 111.69 |
| Standard_B4ms | 4 / 16 | 10 | 140.16 |
| **Standard_F4s_v2** (default) | 4 / 8 | 10 | 141.62 |
| Standard_D4s_v3 | 4 / 16 | 10 | 167.90 |

`Standard_F4s_v2` is the default: dedicated CPU for ~$1.50/mo more than the
burstable `Standard_B4ms`, and Infoblox states NIOS-X resources should be
dedicated. To reach the cheaper `Standard_B4als_v2`, request a quota increase
for the `standardBasv2Family` in GermanyWestCentral first.

`Total Regional vCPUs` is 10, so one 4-vCPU server fits with room to spare.

## Networking

Each demo is self-contained and tears down cleanly:

- **AWS** — VPC `10.90.0.0/24`, one public subnet, internet gateway, default
  route, security group. Egress is open (that is what the join needs); DNS/53 is
  allowed only from the VPC CIDR, not the internet.
- **Azure** — resource group, VNet `10.91.0.0/24`, one subnet, NSG, static
  public IP. Azure's default rules already permit all outbound and deny inbound
  from the internet; only DNS/53 from `VirtualNetwork` is added.

No UDDI IPAM allocation here — unlike the `vpc-aws` / `vpc-azure` demos, these
use fixed CIDRs so the deployment has no dependency beyond the join token.

## Azure marketplace prerequisites

The image is a paid-listing BYOL marketplace item, which means two things:

1. The VM needs a `plan` block — already in `main.tf`.
2. The subscription must have **accepted the publisher terms**, once:

```bash
az vm image terms accept --urn infoblox:infoblox-nios-x-vm:infoblox-nios-x-vm:4.1.10
```

The workflow checks this before running Terraform and fails with an explicit
message rather than a confusing provider error.

Image coordinates:

```
publisher = infoblox
offer     = infoblox-nios-x-vm
sku       = infoblox-nios-x-vm
version   = 4.1.10        (4.0.0 also published)
```

## Running it

### GitHub Actions

1. Actions → **UDDI - NIOS-X on AWS / Azure** → Run workflow
2. Toggle `deploy_aws` and/or `deploy_azure`, pick sizes
3. `name_suffix` lets you run several side by side
4. Select `action: apply`

Uses the existing `dev` environment secrets — `AWS_ACCESS_KEY_ID`,
`AWS_SECRET_ACCESS_KEY`, `ARM_*` and `NIOSX_JOIN_TOKEN`. No new secrets.

### Locally

```bash
cd live/demos/niosx-aws          # or niosx-azure
cp terraform.tfvars.example terraform.tfvars   # add the join token
terraform init
terraform apply -auto-approve
```

## Notes and limits

- **Azure demands an admin credential** on every Linux VM even though NIOS-X
  exposes no SSH. Terraform generates a throwaway RSA key with `tls_private_key`
  purely to satisfy the API; it is never used and needs no secret. The key
  material does land in state.
- **Public IPs.** Both servers get one so they can reach the Infoblox Portal
  directly. Swap in a NAT gateway if outbound-only is required.
- **Join tokens are secrets** and appear in cloud-init user-data, which is
  readable from instance metadata by anything on the box.
- **Cost.** These are the cheapest supported sizes, not free. Destroy the demo
  when finished — `action: destroy` removes the VM and all its networking.
