# GitHub Secrets Configuration

This document lists all required GitHub Secrets and Variables for the Multi-Cloud VPC/VNet Provisioning demo.

## Environment: `dev`

Navigate to: **Repository Settings → Secrets and variables → Actions → Environment secrets (dev)**

### UDDI Configuration

| Secret Name | Value | Description |
|------------|-------|-------------|
| `BLOXONE_API_KEY` | `<your-api-key>` | Infoblox UDDI API Key |
| `AWS_BLOCK_ID` | `144afa8d-c3b9-11f0-8a75-c6247830495c` | UDDI Address Block ID for AWS (10.42.0.0/16) |
| `AZURE_BLOCK_ID` | `1c129cd3-c3b9-11f0-8133-961b76f740b0` | UDDI Address Block ID for Azure (10.44.0.0/16) |
| `GCP_BLOCK_ID` | `243c312e-c3b9-11f0-8133-961b76f740b0` | UDDI Address Block ID for GCP (10.43.0.0/16) |
| `IPAM_SPACE_ID` | `ipam/ip_space/faf01af9-c3b8-11f0-8a75-c6247830495c` | UDDI IPAM Space ID |

### AWS Configuration

| Secret Name | Value | Description |
|------------|-------|-------------|
| `AWS_ACCESS_KEY_ID` | `<your-access-key>` | IAM User Access Key |
| `AWS_SECRET_ACCESS_KEY` | `<your-secret-key>` | IAM User Secret Key |

**Required IAM Permissions:**
- `ec2:CreateVpc`, `ec2:DeleteVpc`, `ec2:DescribeVpcs`
- `ec2:ModifyVpcAttribute`
- `ec2:CreateTags`, `ec2:DeleteTags`, `ec2:DescribeTags`
- `ec2:CreateInternetGateway`, `ec2:DeleteInternetGateway`, `ec2:DescribeInternetGateways`
- `ec2:AttachInternetGateway`, `ec2:DetachInternetGateway`

Or use managed policy: `AmazonVPCFullAccess`

### Azure Configuration

| Secret Name | Value | Description |
|------------|-------|-------------|
| `ARM_CLIENT_ID` | `<service-principal-app-id>` | Azure Service Principal Application ID |
| `ARM_CLIENT_SECRET` | `<service-principal-password>` | Azure Service Principal Password |
| `ARM_SUBSCRIPTION_ID` | `<azure-subscription-id>` | Azure Subscription ID |
| `ARM_TENANT_ID` | `<azure-tenant-id>` | Azure AD Tenant ID |

**Required Azure Role:**
- `Contributor` role on the subscription or resource group

### Azure DNS Configuration (for DNS demo)

| Secret Name | Value | Description |
|------------|-------|-------------|
| `AZURE_DNS_RESOURCE_GROUP` | `<resource-group>` | Resource Group containing the DNS zone |

**Note:** 
- Zone name is automatically determined based on selected provider (`az.gh.blox42.rocks` for Azure DNS)
- Reuses the same Azure credentials (`ARM_*` secrets) from VPC demo
- Requires `DNS Zone Contributor` role or `Contributor` role on the resource group

**Create Service Principal:**
```bash
az ad sp create-for-rbac --name "GitHub-Actions-UDDI-Demo" \
  --role="Contributor" \
  --scopes="/subscriptions/<subscription-id>"
```

### Cloudflare Configuration (for DNS demo)

| Secret Name | Value | Description |
|------------|-------|-------------|
| `CF_API_TOKEN` | `<cloudflare-api-token>` | Cloudflare API Token |
| `CF_ZONE_ID` | `<cloudflare-zone-id>` | Cloudflare Zone ID |

**Required Cloudflare Permissions:**
- `Zone:Read` and `DNS:Read` for DNS verification
- Token can be created at: https://dash.cloudflare.com/profile/api-tokens

### GCP Configuration

| Secret Name | Value | Description |
|------------|-------|-------------|
| `GCP_CREDENTIALS` | `<service-account-json-key>` | GCP Service Account JSON Key (entire JSON) |
| `GCP_PROJECT_ID` | `<your-gcp-project-id>` | GCP Project ID |

**Required GCP Roles:**
- `Compute Network Admin` (`roles/compute.networkAdmin`)
- `Compute Security Admin` (`roles/compute.securityAdmin`)

**Create Service Account:**
```bash
gcloud iam service-accounts create github-actions-uddi \
  --display-name="GitHub Actions UDDI Demo"

gcloud projects add-iam-policy-binding <project-id> \
  --member="serviceAccount:github-actions-uddi@<project-id>.iam.gserviceaccount.com" \
  --role="roles/compute.networkAdmin"

gcloud iam service-accounts keys create key.json \
  --iam-account=github-actions-uddi@<project-id>.iam.gserviceaccount.com
```

### Variables (not secrets)

Navigate to: **Repository Settings → Secrets and variables → Actions → Variables**

| Variable Name | Value | Description |
|--------------|-------|-------------|
| `BLOXONE_HOST` | `https://csp.infoblox.com` | Infoblox UDDI CSP URL |

---

## How to Add Secrets

1. Go to **Repository Settings** → **Secrets and variables** → **Actions**
2. Select **Environments** → **dev**
3. Click **Add secret** for each secret listed above
4. For variables, go to **Variables** tab and click **New repository variable**

---

## Security Notes

- ✅ Never commit secrets to the repository
- ✅ Rotate API keys and credentials regularly
- ✅ Use least-privilege IAM policies
- ✅ Monitor GitHub Actions logs for exposed secrets (GitHub auto-redacts them)
- ✅ Use environment protection rules to require approvals for production deployments

---

## Verification

After adding all secrets, verify by running the Multi-Cloud VPC Provisioning workflow with `action: apply` for a single cloud provider first (e.g., AWS only).

Check workflow logs for:
- ✅ Terraform successfully queries UDDI for next available subnet
- ✅ Cloud provider VPC/VNet created with UDDI-allocated CIDR
- ✅ UDDI subnet resource created with proper tags
- ✅ Job summary displays allocation details

---

**Last Updated:** 2025-01-17  
**Repository:** https://github.com/stefanriegel/uddi-demo
