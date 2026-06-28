#!/usr/bin/env bash
# Per-instance Terraform plan/apply loop for one cloud's network demo.
# Orchestration only: the calling job keeps cache, verification, and the job
# summary. See docs/adr/0001-cloud-demos-stay-standalone.md (this collapses the
# workflow loop, not the standalone Terraform roots).
#
# Reads its config from env (see action.yml). Runs in the cloud's tf-dir.
set -euo pipefail

CLOUD="${CLOUD:?CLOUD required}"
EMOJI="${EMOJI:-🔷}"
COUNT="${COUNT:-1}"
ACTION="${ACTION:-apply}"
CLOUD_UPPER=$(echo "$CLOUD" | tr '[:lower:]' '[:upper:]')

emit() { [ -n "${GITHUB_OUTPUT:-}" ] && printf '%s\n' "$1" >> "$GITHUB_OUTPUT"; return 0; }

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ${EMOJI} ${CLOUD_UPPER}: deploying ${COUNT} network(s) via UDDI IPAM"
echo "╚══════════════════════════════════════════════════════════════╝"

if [ "$ACTION" != "apply" ]; then
  echo "⚠️ Destroy disabled in workflow — use the Auto Cleanup workflow instead"
  echo "Resources are cleaned up automatically at midnight or via manual cleanup trigger"
  emit "results=[]"
  emit "duration=0"
  exit 0
fi

# Cloud-specific -var pairs, one "name=value" per line.
VAR_ARGS=()
while IFS= read -r kv; do
  [ -n "$kv" ] && VAR_ARGS+=(-var "$kv")
done <<< "${EXTRA_VARS:-}"

start=$(date +%s)
result_file=$(mktemp)

terraform init -input=false -no-color -reconfigure

for i in $(seq 1 "$COUNT"); do
  name="${NETWORK_NAME}-${CLOUD}-${i}"
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║  ${EMOJI} Phase ${i}/${COUNT}: ${name}"
  echo "╚══════════════════════════════════════════════════════════════╝"

  terraform plan -input=false -no-color \
    -var="bloxone_host=${BLOXONE_HOST}" \
    -var="bloxone_api_key=${BLOXONE_API_KEY}" \
    -var="${NAME_VAR}=${name}" \
    -var="subnet_size=${SUBNET_SIZE}" \
    "${VAR_ARGS[@]}" \
    -state="terraform-${i}.tfstate" \
    -out="tfplan-${i}"

  terraform apply -input=false -auto-approve -no-color \
    -state="terraform-${i}.tfstate" \
    "tfplan-${i}"

  id=$(terraform output -state="terraform-${i}.tfstate" -raw "${ID_OUTPUT}")
  cidr=$(terraform output -state="terraform-${i}.tfstate" -raw "${CIDR_OUTPUT}")
  echo "${name}|${id}|${cidr}" >> "$result_file"
  echo "✅ ${CLOUD_UPPER} ${i}: ${id} (${cidr})"
  echo ""
done

dur=$(($(date +%s) - start))
results=$(jq -R -s -c 'split("\n") | map(select(length > 0))' < "$result_file")
emit "results=${results}"
emit "duration=${dur}"
echo "✅ ${CLOUD_UPPER} deployment completed in ${dur}s"
