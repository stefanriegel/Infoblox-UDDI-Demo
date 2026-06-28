#!/usr/bin/env bash
# Cloud-side teardown of demo VPC/VNet resources — the mirror of uddi.sh.
# One find/delete interface; each cloud adapter owns its own discovery filter
# (the tag-casing contract, ADR-0002) and its dependency-ordered teardown.
# find emits a uniform descriptor array [{name,id,region}]; delete consumes it
# and re-discovers each resource's dependencies at teardown time.
# Plumbing only: the calling workflow keeps the presented job summary.
# See docs/adr/0003-workflow-narration-is-demo-ui.md and CONTEXT.md ("Cloud-cleanup").
#
# Usage: cleanup.sh <find|delete> <aws|azure|gcp>
# Env:   per-cloud creds (see action.yml), CLOUD_RESOURCES (delete), AWS_REGIONS (aws)
#
# Note: no `set -e` — cloud CLIs fail noisily and teardown is best-effort; each
# call is guarded and counted explicitly. -u and pipefail still catch real bugs.
set -uo pipefail

OP="${1:?operation is required (find|delete)}"
CLOUD="${2:?cloud is required (aws|azure|gcp)}"

emit() { [ -n "${GITHUB_OUTPUT:-}" ] && echo "$1=$2" >> "$GITHUB_OUTPUT"; return 0; }

emit_json() { # emit_json <name> <file>
  [ -n "${GITHUB_OUTPUT:-}" ] || return 0
  {
    echo "$1<<__CC_EOF__"
    cat "$2"
    echo "__CC_EOF__"
  } >> "$GITHUB_OUTPUT"
}

bool() { [ "$1" -gt 0 ] && echo "true" || echo "false"; }

banner() {
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║  $1"
  echo "╚══════════════════════════════════════════════════════════════╝"
}

# --- auth (idempotent; needed by both find and delete) ----------------------

auth_aws() { :; } # aws CLI reads AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY from env

auth_azure() {
  [ -n "${ARM_CLIENT_ID:-}" ] || return 0
  az login --service-principal \
    --username "${ARM_CLIENT_ID}" \
    --password "${ARM_CLIENT_SECRET}" \
    --tenant "${ARM_TENANT_ID}" --output none 2>/dev/null || true
  az account set --subscription "${ARM_SUBSCRIPTION_ID}" 2>/dev/null || true
}

auth_gcp() {
  [ -n "${GOOGLE_CREDENTIALS:-}" ] || return 0
  echo "${GOOGLE_CREDENTIALS}" | gcloud auth activate-service-account --key-file=- 2>/dev/null || true
  gcloud config set project "${GCP_PROJECT_ID}" 2>/dev/null || true
}

# --- find: emit [{name,id,region}] ------------------------------------------

find_aws() {
  banner "🔍 AWS: scanning for demo VPCs (Demo=true + ManagedBy=terraform)"
  # shellcheck disable=SC2206  # intentional word-split on space-separated regions
  local regions=(${AWS_REGIONS:-})
  local all='[]'
  for region in "${regions[@]}"; do
    echo "Checking region: ${region}"
    local vpcs
    vpcs=$(aws ec2 describe-vpcs \
      --region "${region}" \
      --filters "Name=tag:ManagedBy,Values=terraform" "Name=tag:Demo,Values=true" \
      --query 'Vpcs[].{name: (Tags[?Key==`Name`].Value | [0]), id: VpcId}' \
      --output json 2>/dev/null || echo '[]')
    # Tag each descriptor with its region (delete needs it; Azure/GCP leave it "").
    vpcs=$(echo "$vpcs" | jq -c --arg r "$region" 'map(. + {region: $r})')
    all=$(jq -s -c '.[0] + .[1]' <(echo "$all") <(echo "$vpcs"))
  done
  emit_result "$all"
}

find_azure() {
  banner "🔍 Azure: scanning for demo resource groups (demo=true)"
  local rgs
  rgs=$(az group list --tag demo=true \
    --query '[].{name: name, id: name, region: ""}' \
    --output json 2>/dev/null || echo '[]')
  emit_result "$rgs"
}

find_gcp() {
  banner "🔍 GCP: scanning for demo VPC networks (description:UDDI)"
  local nets
  nets=$(gcloud compute networks list --filter="description:UDDI" \
    --format=json 2>/dev/null \
    | jq -c '[.[] | {name: .name, id: .name, region: ""}]' 2>/dev/null || echo '[]')
  emit_result "$nets"
}

emit_result() { # emit_result <json-array>
  local all="$1" total
  echo "$all" > /tmp/cloud_cleanup_result.json
  total=$(echo "$all" | jq -r 'length')
  echo "----------------------------------------"
  echo "Found ${total} demo ${CLOUD} resource(s)"
  [ "$total" -gt 0 ] && echo "$all" | jq -r '.[] | "  - \(.name) (\(.id))\(if .region != "" then " [" + .region + "]" else "" end)"'
  emit_json result /tmp/cloud_cleanup_result.json
  emit count "$total"
  emit has "$(bool "$total")"
}

# --- delete: consume descriptors, re-discover deps, tear down ---------------

delete_aws() { # delete_aws <descriptor-json>
  local d="$1" id region name
  id=$(echo "$d" | jq -r '.id')
  region=$(echo "$d" | jq -r '.region')
  name=$(echo "$d" | jq -r '.name // "unnamed"')
  echo "🗑️ Deleting VPC ${id} (${name}) in ${region}"

  # Detach + delete attached internet gateways first (dependency order).
  local igws igw
  igws=$(aws ec2 describe-internet-gateways --region "${region}" \
    --filters "Name=attachment.vpc-id,Values=${id}" \
    --query 'InternetGateways[].InternetGatewayId' --output text 2>/dev/null || true)
  for igw in ${igws}; do
    echo "  Detaching + deleting IGW: ${igw}"
    aws ec2 detach-internet-gateway --region "${region}" \
      --internet-gateway-id "${igw}" --vpc-id "${id}" 2>/dev/null || true
    aws ec2 delete-internet-gateway --region "${region}" \
      --internet-gateway-id "${igw}" 2>/dev/null || true
  done

  aws ec2 delete-vpc --region "${region}" --vpc-id "${id}" 2>/dev/null
}

delete_azure() { # delete_azure <descriptor-json>
  local d="$1" name
  name=$(echo "$d" | jq -r '.name')
  echo "🗑️ Deleting resource group: ${name} (cascades)"
  az group delete --name "${name}" --yes --no-wait 2>/dev/null
}

delete_gcp() { # delete_gcp <descriptor-json>
  local d="$1" name subnets sname sregion
  name=$(echo "$d" | jq -r '.name')
  echo "🗑️ Deleting VPC network: ${name}"
  # Delete member subnets first (dependency order).
  subnets=$(gcloud compute networks subnets list --network="${name}" \
    --format="value(name,region)" 2>/dev/null || true)
  while read -r sname sregion; do
    [ -n "${sname}" ] || continue
    echo "  Deleting subnet: ${sname} (${sregion})"
    gcloud compute networks subnets delete "${sname}" --region="${sregion}" --quiet 2>/dev/null || true
  done <<< "${subnets}"
  gcloud compute networks delete "${name}" --quiet 2>/dev/null
}

delete_resources() {
  banner "🗑️  $(echo "$CLOUD" | tr '[:lower:]' '[:upper:]'): tearing down demo resources"
  local start count i d deleted=0 failed=0 dur
  start=$(date +%s)
  count=$(echo "${CLOUD_RESOURCES:-[]}" | jq -r 'length')
  for i in $(seq 0 $((count - 1))); do
    [ "$count" -eq 0 ] && break
    d=$(echo "${CLOUD_RESOURCES}" | jq -c ".[$i]")
    if "delete_${CLOUD}" "$d"; then
      echo "  ✅ done"
      deleted=$((deleted + 1))
    else
      echo "  ⚠️ teardown failed"
      failed=$((failed + 1))
    fi
    echo ""
  done
  dur=$(($(date +%s) - start))
  echo "Summary: ${deleted} torn down, ${failed} failed in ${dur}s"
  emit deleted "$deleted"
  emit failed "$failed"
  emit duration "$dur"
  [ "$failed" -gt 0 ] && exit 1
  return 0
}

# --- dispatch ----------------------------------------------------------------

case "$CLOUD" in
  aws | azure | gcp) "auth_${CLOUD}" ;;
  *) echo "Unknown cloud: ${CLOUD}" >&2; exit 2 ;;
esac

case "$OP" in
  find)   "find_${CLOUD}" ;;
  delete) delete_resources ;;
  *) echo "Unknown operation: ${OP}" >&2; exit 2 ;;
esac
