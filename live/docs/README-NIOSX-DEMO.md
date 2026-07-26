# NIOS-X on Proxmox Demo

Clones the `NIOS-X-TEMPLATE` VM on the `pve-fsn1-dc13` cluster, seeds it with a
cloud-init join token, attaches it to `vnet5000` with VLAN tag 32, and starts it.
The server registers itself with the Infoblox Portal on first boot.

- Terraform: `live/demos/niosx-proxmox/`
- Workflow: `.github/workflows/niosx-deployment.yml`
- Seed builder: `scripts/build-niosx-seed.sh`

## Flow

```
scripts/build-niosx-seed.sh          seed.iso  (CIDATA, host_setup.jointoken)
              |
              v
proxmox_virtual_environment_file     upload to ISO datastore via Proxmox API
              |
              v
proxmox_virtual_environment_vm       full clone of VMID 1061
              |                        cdrom  ide2 = seed.iso
              |                        net0   vnet5000, VLAN 32
              v                        4 vCPU / 8192 MB, started
     Infoblox Portal (NIOS-X join)
```

## Why a seed ISO and not a snippet

Proxmox stores custom cloud-init as *snippets*, but the Proxmox API has no
snippet upload endpoint — writing one requires SSH to a node, which this
project does not have. The Infoblox KVM deployment guide uses a NoCloud seed
ISO instead, and ISO upload *is* a plain API call. So Terraform builds nothing
by hand: it uploads the seed image over the same API token it uses for the
clone, and every apply carries a freshly rendered join token.

## Cluster facts this demo relies on

| Thing | Value | Why it matters |
|---|---|---|
| Template | VMID `1061` (`NIOS-X-TEMPLATE`) on `pve-fsn1-dc17` | Clone source |
| Clone datastore | `storage` (NFS, shared) | Shared, so the clone can land on any node |
| ISO datastore | `ISO` (NFS, shared) | Must allow `iso` content |
| Bridge | `vnet5000` (VXLAN zone `vx4000`, `vlanaware=1`) | VLAN-aware, so tag 32 is valid |
| CD-ROM slot | `ide2` | Free in the template (`ide2: none,media=cdrom`) |
| Resource pool | `LAB-SRiegel` | Clone is assigned to it; `pool_id` updates in place, no rebuild |

The template's boot order starts with `ide2`. The seed ISO has no boot sector,
so the BIOS falls through to `scsi0` — no boot-order change needed.

## Cloud-init payload

Per the Infoblox templates, DHCP means no `network-config` file is needed:

```yaml
#cloud-config
host_setup:
  jointoken: <NIOSX_JOIN_TOKEN>
  tags:
    - demo=true
    - automation=github-actions
    - hostname=<vm_name>
```

## Running it

### GitHub Actions

1. Actions → **UDDI - NIOS-X on Proxmox** → Run workflow
2. Set VM name, target node (`auto` picks the first online node), resource pool, VLAN tag, sizing
3. Select `action: apply`
4. The job summary reports VMID, node, MAC and power state

### Locally

```bash
cd live/demos/niosx-proxmox
cp terraform.tfvars.example terraform.tfvars   # fill in the API token

NIOSX_JOIN_TOKEN=<token> ../../../scripts/build-niosx-seed.sh \
  --hostname niosx-demo --out seed.iso

terraform init
terraform plan
terraform apply -auto-approve
```

Requires one of `cloud-localds`, `genisoimage`, `xorriso` or `hdiutil` (macOS).

## Notes and limits

- **Single NIC.** The template carries `net0` and `net1`, both on `vnet5000`.
  The clone gets one management NIC, matching the Infoblox KVM reference
  deployment. Two NICs in the same broadcast domain both running DHCP is not
  something NIOS-X expects.
- **No guest agent.** NIOS-X ships without `qemu-guest-agent`, so `agent` is
  disabled. Terraform cannot report the VM's IP; find it via DHCP leases or the
  Infoblox Portal.
- **CPU type `host`.** Preserved from the template. Cross-node live migration
  between differing CPUs would need a generic type.
- **Join tokens are secrets.** `seed.iso` contains the token in plaintext and is
  gitignored (`*.iso`). The uploaded ISO also sits readable on the `ISO`
  datastore — destroy removes it along with the VM.
- **Destroy** removes the VM and its seed ISO. Re-applying builds a new seed
  with a fresh `instance-id`, so cloud-init re-runs on the new clone.
