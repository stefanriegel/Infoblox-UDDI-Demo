#!/usr/bin/env bash
# Query one downstream DNS provider for the demo record and normalize the result.
# The cloud-DNS sibling of the uddi action: four adapters (Cloudflare/Azure/
# Route53/GCP) behind one interface, all producing the SAME dns-record.json
# contract that the job summary renders from. Only the SELECTED provider is
# queried — one writer, no last-wins.
#
# Narration: like uddi.sh, this emits the per-provider DASHBOARD INFO to the run
# log. The $GITHUB_STEP_SUMMARY rendering stays in the workflow and reads
# dns-record.json. See docs/adr/0003-workflow-narration-is-demo-ui.md and
# CONTEXT.md ("DNS provider record").
#
# Writes <output-dir>/<provider>-response.json (raw proof) and
# <output-dir>/dns-record.json (normalized). dns-record.json is written only when
# a provider was actually queried (creds + zone resolved) — matching the prior
# behavior where a missing/unconfigured provider rendered no downstream section.
#
# Env: see action.yml. set -e omitted — provider CLIs are best-effort.
set -uo pipefail

DNS_PROVIDER="${DNS_PROVIDER:?dns-provider is required}"
ZONE_FQDN="${ZONE_FQDN:?zone-fqdn is required}"   # e.g. "az.gh.blox42.rocks."
RECORD_NAME="${RECORD_NAME:-}"
TYPE="${RECORD_TYPE:?record-type is required}"
OUT="${OUTPUT_DIR:-live/demos/dns}"

FQDN="${RECORD_NAME}.${ZONE_FQDN}"
FQDN="${FQDN%.}."                                  # exactly one trailing dot

emit() { [ -n "${GITHUB_OUTPUT:-}" ] && echo "$1=$2" >> "$GITHUB_OUTPUT"; return 0; }

# Normalize the human provider label to a canonical key.
case "$DNS_PROVIDER" in
  Cloudflare*)   PROVIDER=cloudflare ;;
  "Azure DNS"*)  PROVIDER=azure ;;
  Route53*)      PROVIDER=route53 ;;
  "Cloud DNS"*)  PROVIDER=gcp ;;
  *) echo "Unknown DNS provider: ${DNS_PROVIDER}" >&2; exit 2 ;;
esac

# write_record — the one place the dns-record.json contract is defined.
# Reads the REC_* globals each adapter fills in.
write_record() {
  jq -n \
    --arg provider "$PROVIDER" \
    --argjson found "${REC_FOUND:-false}" \
    --arg id "${REC_ID:-}" \
    --arg fqdn "${REC_FQDN:-}" \
    --arg type "${REC_TYPE:-}" \
    --arg target "${REC_TARGET:-}" \
    --arg ttl "${REC_TTL:-}" \
    --arg proxied "${REC_PROXIED:-}" \
    --arg provisioning_state "${REC_PROV_STATE:-}" \
    --arg console_url "${REC_CONSOLE_URL:-}" \
    '{provider:$provider,found:$found,id:$id,fqdn:$fqdn,type:$type,target:$target,ttl:$ttl,proxied:$proxied,provisioning_state:$provisioning_state,console_url:$console_url}' \
    > "${OUT}/dns-record.json"
  emit found "${REC_FOUND:-false}"
  emit provider "$PROVIDER"
}

banner() {
  echo ""
  echo "============================================"
  echo "$1"
  echo "============================================"
  echo ""
}

# --- Cloudflare -------------------------------------------------------------

query_cloudflare() {
  banner "☁️  CLOUDFLARE DASHBOARD INFO"
  if [ -z "${CF_API_TOKEN:-}" ]; then
    echo "ℹ️  Cloudflare API credentials not configured"
    echo "   Set CF_API_TOKEN and CF_ZONE_ID secrets to enable dashboard info"
    return 0
  fi

  local zone_id="${CF_ZONE_ID:-}" zone_name
  if [ -z "$zone_id" ]; then
    zone_name="${FQDN#*.}"; zone_name="${zone_name%.}"
    echo "CF_ZONE_ID not set, looking up zone for ${zone_name}..."
    local lookup
    lookup=$(curl -s -X GET "https://api.cloudflare.com/v4/zones?name=${zone_name}" \
      -H "Authorization: Bearer ${CF_API_TOKEN}" -H "Content-Type: application/json")
    zone_id=$(echo "$lookup" | jq -r '.result[0].id // empty' 2>/dev/null)
    if [ -n "$zone_id" ]; then echo "✅ Found Zone ID: ${zone_id}"; else
      echo "⚠️  Zone '${zone_name}' not found in Cloudflare account"; return 0
    fi
  fi

  local record_name="${FQDN%.}" resp count
  echo "Querying Cloudflare API for: ${record_name} (${TYPE})"
  resp=$(curl -s -X GET "https://api.cloudflare.com/v4/zones/${zone_id}/dns_records?name=${record_name}&type=${TYPE}" \
    -H "Authorization: Bearer ${CF_API_TOKEN}" -H "Content-Type: application/json")
  echo "$resp" > "${OUT}/cf-response.json"

  REC_CONSOLE_URL="https://dash.cloudflare.com/${zone_id}/dns/records"
  count=$(echo "$resp" | jq -r '.result | length' 2>/dev/null || echo 0)
  if [ "${count:-0}" -gt 0 ]; then
    echo "✅ Record found in Cloudflare"
    REC_FOUND=true
    REC_ID=$(echo "$resp" | jq -r '.result[0].id')
    REC_FQDN=$(echo "$resp" | jq -r '.result[0].name')
    REC_TYPE=$(echo "$resp" | jq -r '.result[0].type')
    REC_TARGET=$(echo "$resp" | jq -r '.result[0].content')
    REC_TTL=$(echo "$resp" | jq -r '.result[0].ttl')
    REC_PROXIED=$(echo "$resp" | jq -r '.result[0].proxied')
    echo "📋 Record Details:"
    echo "   ID: ${REC_ID}"
    echo "   Name: ${REC_FQDN}"
    echo "   Type: ${REC_TYPE}"
    echo "   Content: ${REC_TARGET}"
    echo "   TTL: ${REC_TTL}"
    [ "$REC_PROXIED" = "true" ] && echo "   Proxy: 🟠 ENABLED (Orange Cloud)" || echo "   Proxy: ⚪ DISABLED (DNS Only)"
    echo "🔗 Cloudflare Dashboard: ${REC_CONSOLE_URL}"
  else
    echo "⚠️  Record not yet synced to Cloudflare (UDDI sync may take a few moments)"
    REC_FOUND=false
  fi
  write_record
}

# --- Azure DNS --------------------------------------------------------------

query_azure() {
  banner "☁️  AZURE DNS DASHBOARD INFO"
  if [ -z "${ARM_CLIENT_ID:-}" ] || [ -z "${AZURE_DNS_RESOURCE_GROUP:-}" ]; then
    echo "ℹ️  Azure DNS credentials not configured"
    echo "   Set ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID,"
    echo "   and AZURE_DNS_RESOURCE_GROUP secrets to enable dashboard info"
    return 0
  fi

  local zone_name="${ZONE_FQDN%.}" resp record_id rg_enc zone_enc
  echo "Authenticating with Azure..."
  az login --service-principal --username "${ARM_CLIENT_ID}" --password "${ARM_CLIENT_SECRET}" \
    --tenant "${ARM_TENANT_ID}" --output none 2>/dev/null
  az account set --subscription "${ARM_SUBSCRIPTION_ID}" 2>/dev/null

  echo "Querying Azure DNS for: ${RECORD_NAME} (${TYPE}) in zone ${zone_name}"
  resp=$(az network dns record-set "${TYPE}" show \
    --resource-group "${AZURE_DNS_RESOURCE_GROUP}" --zone-name "${zone_name}" \
    --name "${RECORD_NAME}" --output json 2>/dev/null || echo '{}')
  echo "$resp" > "${OUT}/azure-response.json"

  rg_enc=$(echo "${AZURE_DNS_RESOURCE_GROUP}" | jq -sRr @uri)
  zone_enc=$(echo "${zone_name}" | jq -sRr @uri)   # was AZURE_DNS_ZONE_NAME (unset) — fixed
  REC_CONSOLE_URL="https://portal.azure.com/#@${ARM_TENANT_ID}/resource/subscriptions/${ARM_SUBSCRIPTION_ID}/resourceGroups/${rg_enc}/providers/Microsoft.Network/dnszones/${zone_enc}/overview"

  record_id=$(echo "$resp" | jq -r '.id // empty' 2>/dev/null)
  if [ -n "$record_id" ]; then
    echo "✅ Record found in Azure DNS"
    REC_FOUND=true
    REC_ID="$record_id"
    REC_FQDN=$(echo "$resp" | jq -r '.fqdn')
    REC_TYPE="$TYPE"
    REC_TTL=$(echo "$resp" | jq -r '.ttl')
    REC_PROV_STATE=$(echo "$resp" | jq -r '.provisioningState')
    case "$TYPE" in
      A)     REC_TARGET=$(echo "$resp" | jq -r '.aRecords[].ipv4Address' | tr '\n' ', ' | sed 's/,$//') ;;
      AAAA)  REC_TARGET=$(echo "$resp" | jq -r '.aaaaRecords[].ipv6Address' | tr '\n' ', ' | sed 's/,$//') ;;
      CNAME) REC_TARGET=$(echo "$resp" | jq -r '.cnameRecord.cname') ;;
      TXT)   REC_TARGET=$(echo "$resp" | jq -r '.txtRecords[].value[]' | tr '\n' ', ' | sed 's/,$//') ;;
    esac
    echo "📋 Record Details:"
    echo "   ID: ${REC_ID}"
    echo "   FQDN: ${REC_FQDN}"
    echo "   Type: ${REC_TYPE}"
    echo "   Records: ${REC_TARGET}"
    echo "   TTL: ${REC_TTL}"
    echo "   Provisioning State: ${REC_PROV_STATE}"
    echo "🔗 Azure Portal: ${REC_CONSOLE_URL}"
  else
    echo "⚠️  Record not yet synced to Azure DNS (UDDI sync may take a few moments)"
    REC_FOUND=false
  fi
  write_record
}

# --- AWS Route53 ------------------------------------------------------------

query_route53() {
  banner "☁️  AWS ROUTE53 DASHBOARD INFO"
  if [ -z "${AWS_ACCESS_KEY_ID:-}" ] || [ -z "${ROUTE53_HOSTED_ZONE_ID:-}" ]; then
    echo "ℹ️  Route53 credentials not configured"
    echo "   Set AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, and ROUTE53_HOSTED_ZONE_ID secrets to enable dashboard info"
    return 0
  fi

  local record_fqdn="${RECORD_NAME}.${ZONE_FQDN}" resp count region="${AWS_REGION:-us-east-1}"
  echo "Querying Route53 for: ${record_fqdn} (${TYPE}) [zone ${ROUTE53_HOSTED_ZONE_ID}, ${region}]"
  resp=$(aws route53 list-resource-record-sets \
    --hosted-zone-id "${ROUTE53_HOSTED_ZONE_ID}" \
    --query "ResourceRecordSets[?Name=='${record_fqdn}' && Type=='${TYPE}']" \
    --region "${region}" --output json 2>/dev/null || echo '[]')
  echo "$resp" > "${OUT}/route53-response.json"

  REC_CONSOLE_URL="https://console.aws.amazon.com/route53/v2/hostedzones#ListRecordSets/${ROUTE53_HOSTED_ZONE_ID}"
  count=$(echo "$resp" | jq -r 'length' 2>/dev/null || echo 0)
  if [ "${count:-0}" -gt 0 ]; then
    echo "✅ Record found in Route53"
    REC_FOUND=true
    REC_FQDN=$(echo "$resp" | jq -r '.[0].Name')
    REC_TYPE=$(echo "$resp" | jq -r '.[0].Type')
    REC_TTL=$(echo "$resp" | jq -r '.[0].TTL')
    case "$TYPE" in
      CNAME) REC_TARGET=$(echo "$resp" | jq -r '.[0].ResourceRecords[0].Value') ;;
      *)     REC_TARGET=$(echo "$resp" | jq -r '.[0].ResourceRecords[].Value' | tr '\n' ', ' | sed 's/,$//') ;;
    esac
    echo "📋 Record Details:"
    echo "   Name: ${REC_FQDN}"
    echo "   Type: ${REC_TYPE}"
    echo "   Values: ${REC_TARGET}"
    echo "   TTL: ${REC_TTL}"
    echo "🔗 AWS Console: ${REC_CONSOLE_URL}"
  else
    echo "⚠️  Record not yet synced to Route53 (UDDI sync may take a few moments)"
    REC_FOUND=false
  fi
  write_record
}

# --- GCP Cloud DNS ----------------------------------------------------------

query_gcp() {
  banner "☁️  GCP CLOUD DNS DASHBOARD INFO"
  if [ -z "${GOOGLE_CREDENTIALS:-}" ] || [ -z "${GCP_PROJECT_ID:-}" ]; then
    echo "ℹ️  Cloud DNS credentials not configured"
    echo "   Set GOOGLE_CREDENTIALS and GCP_PROJECT_ID secrets to enable dashboard info"
    return 0
  fi

  local zone_dns="${ZONE_FQDN}" zone_name record_fqdn resp count
  zone_name=$(echo "${zone_dns}" | sed 's/\.$//' | tr '.' '-')
  record_fqdn="${RECORD_NAME}.${zone_dns}"
  echo "Authenticating with GCP..."
  echo "${GOOGLE_CREDENTIALS}" | gcloud auth activate-service-account --key-file=- 2>/dev/null
  gcloud config set project "${GCP_PROJECT_ID}" 2>/dev/null

  echo "Querying Cloud DNS for: ${record_fqdn} (${TYPE}) in zone ${zone_name}"
  resp=$(gcloud dns record-sets list --zone="${zone_name}" \
    --filter="name:${record_fqdn} AND type:${TYPE}" --format=json 2>/dev/null || echo '[]')
  echo "$resp" > "${OUT}/gcp-response.json"

  REC_CONSOLE_URL="https://console.cloud.google.com/net-services/dns/zones/${zone_name}/rrsets?project=${GCP_PROJECT_ID}"
  count=$(echo "$resp" | jq -r 'length' 2>/dev/null || echo 0)
  if [ "${count:-0}" -gt 0 ]; then
    echo "✅ Record found in Cloud DNS"
    REC_FOUND=true
    REC_FQDN=$(echo "$resp" | jq -r '.[0].name')
    REC_TYPE=$(echo "$resp" | jq -r '.[0].type')
    REC_TTL=$(echo "$resp" | jq -r '.[0].ttl')
    REC_TARGET=$(echo "$resp" | jq -r '.[0].rrdatas[]' | tr '\n' ', ' | sed 's/,$//')
    echo "📋 Record Details:"
    echo "   Name: ${REC_FQDN}"
    echo "   Type: ${REC_TYPE}"
    echo "   Values: ${REC_TARGET}"
    echo "   TTL: ${REC_TTL}"
    echo "🔗 GCP Console: ${REC_CONSOLE_URL}"
  else
    echo "⚠️  Record not yet synced to Cloud DNS (UDDI sync may take a few moments)"
    REC_FOUND=false
  fi
  write_record
}

mkdir -p "$OUT"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔷 Phase 5: DNS Verification & Provider Status              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
"query_${PROVIDER}"
