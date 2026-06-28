#!/usr/bin/env bash
# UDDI access for the cleanup demo — scan and delete demo resources behind one
# canonical is_demo predicate. Plumbing only: the calling workflow keeps the
# presented narration (banners, job summaries).
# See docs/adr/0003-workflow-narration-is-demo-ui.md and CONTEXT.md ("Demo resource").
#
# Usage: uddi.sh find-demo-records | find-demo-subnets | delete
# Env:   UDDI_HOST, UDDI_API_KEY, UDDI_ZONES (records), UDDI_RESOURCES (delete)
set -euo pipefail

HOST="${UDDI_HOST:-https://csp.infoblox.com}"
API_KEY="${UDDI_API_KEY:?UDDI_API_KEY is required}"
OP="${1:?operation is required (find-demo-records|find-demo-subnets|delete)}"

# Canonical "is this a demo resource?" base predicate — ONE definition, shared by
# records and subnets. Per-type extras are layered on by each operation below.
IS_DEMO_BASE='
def is_demo_base:
  (.tags.demo == "true")
  or (.tags.demo == true)
  or ((.tags | type == "array")
      and any(.[]; ((.key == "demo" or .name == "demo")
                    and (.value == "true" or .value == true))));
'

emit() { # emit <name> <value>
  [ -n "${GITHUB_OUTPUT:-}" ] && echo "$1=$2" >> "$GITHUB_OUTPUT"
  return 0
}

emit_json() { # emit_json <name> <file>
  [ -n "${GITHUB_OUTPUT:-}" ] || return 0
  {
    echo "$1<<__UDDI_EOF__"
    cat "$2"
    echo "__UDDI_EOF__"
  } >> "$GITHUB_OUTPUT"
}

get() { # get <path-and-query>
  curl -sS --fail --max-time 30 -X GET \
    -H "Authorization: Token ${API_KEY}" \
    "${HOST}/api/ddi/v1/$1"
}

bool() { [ "$1" -gt 0 ] && echo "true" || echo "false"; }

find_records() {
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║  🔷 UDDI: scanning DNS zones for demo records               ║"
  echo "╚══════════════════════════════════════════════════════════════╝"
  # shellcheck disable=SC2206  # intentional word-split: space-separated FQDNs
  local zones=(${UDDI_ZONES:-})
  local all='[]'
  for zone in "${zones[@]}"; do
    echo "----------------------------------------"
    echo "Checking zone: ${zone}"
    local zr zid
    zr=$(get "dns/auth_zone?_filter=fqdn==%22${zone}%22" || echo '{}')
    zid=$(echo "$zr" | jq -r '.results[0].id // empty')
    if [ -z "$zid" ]; then
      echo "⚠️ Zone not found: ${zone}"
      continue
    fi
    echo "Zone ID: ${zid}"

    # Paginate, guarding against an API that ignores _page (repeating-page hash).
    local accum='[]' page=1 prev='' resp recs cnt hash
    while :; do
      resp=$(get "dns/record?_filter=zone==%22${zid}%22&_fields=id,name_in_zone,type,rdata,tags,comment&_limit=500&_page=${page}") || {
        echo "⚠️ page ${page} failed; stopping pagination"
        break
      }
      recs=$(echo "$resp" | jq '.results // []')
      cnt=$(echo "$recs" | jq -r 'length')
      [ "$cnt" -eq 0 ] && break
      hash=$(echo "$recs" | jq -r 'map(.id) | join("|")')
      if [ -n "$prev" ] && [ "$hash" = "$prev" ]; then
        echo "ℹ️ pagination unsupported (repeating page); stopping after page ${page}"
        break
      fi
      prev="$hash"
      accum=$(jq -s '.[0] + .[1]' <(echo "$accum") <(echo "$recs"))
      [ "$cnt" -lt 500 ] && break
      page=$((page + 1))
      [ "$page" -gt 20 ] && { echo "ℹ️ page safety limit reached; stopping"; break; }
    done

    # Demo records: base predicate OR Terraform-managed comment fallback.
    local prog="${IS_DEMO_BASE} map(select(is_demo_base or (.comment != null and (.comment | test(\"Terraform-managed\"; \"i\")))))"
    local demo dc
    demo=$(echo "$accum" | jq "$prog")
    dc=$(echo "$demo" | jq -r 'length')
    echo "Found ${dc} demo records in ${zone}"
    [ "$dc" -gt 0 ] && echo "$demo" | jq -r --arg z "${zone%.}" '.[] | "  - \(.name_in_zone).\($z) (\(.type))"'
    all=$(jq -s '.[0] + .[1]' <(echo "$all") <(echo "$demo"))
  done

  echo "$all" > /tmp/uddi_result.json
  local total
  total=$(echo "$all" | jq -r 'length')
  echo "========================================"
  echo "Total demo records found: ${total}"
  emit_json result /tmp/uddi_result.json
  emit count "$total"
  emit has "$(bool "$total")"
}

find_subnets() {
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║  🔷 UDDI: scanning IPAM for demo subnets                    ║"
  echo "╚══════════════════════════════════════════════════════════════╝"
  echo "Querying UDDI IPAM for demo subnets..."
  local all demo total
  all=$(get "ipam/subnet?_fields=id,address,cidr,name,tags,comment" || echo '{"results":[]}')
  # Demo subnets: base predicate AND a known cloud tag (scoping is load-bearing —
  # it stops cleanup from touching non-demo subnets that merely carry demo=true).
  local prog="${IS_DEMO_BASE} (.results // []) | map(select(is_demo_base and ((.tags.cloud == \"aws\") or (.tags.cloud == \"azure\") or (.tags.cloud == \"gcp\"))))"
  demo=$(echo "$all" | jq "$prog")
  total=$(echo "$demo" | jq -r 'length')
  echo "Found ${total} demo subnets to release"
  [ "$total" -gt 0 ] && echo "$demo" | jq -r '.[] | "  - \(.name) (\(.address)/\(.cidr)) [\(.tags.cloud)]"'
  echo "$demo" > /tmp/uddi_result.json
  emit_json result /tmp/uddi_result.json
  emit count "$total"
  emit has "$(bool "$total")"
}

delete_resources() {
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║  🗑️  UDDI: deleting demo resources                          ║"
  echo "╚══════════════════════════════════════════════════════════════╝"
  local start ids deleted=0 failed=0 id code dur
  start=$(date +%s)
  ids=$(echo "${UDDI_RESOURCES:-[]}" | jq -r 'if type=="object" and has("results") then .results[].id elif type=="array" then .[].id else empty end')
  for id in $ids; do
    echo "Deleting ${id}..."
    code=$(curl -s -w "%{http_code}" -o /tmp/uddi_delete.json -X DELETE \
      -H "Authorization: Token ${API_KEY}" \
      "${HOST}/api/ddi/v1/${id}")
    if [ "$code" -eq 200 ] || [ "$code" -eq 204 ]; then
      echo "✅ Deleted (HTTP ${code})"
      deleted=$((deleted + 1))
    elif [ "$code" -eq 404 ]; then
      echo "ℹ️ Already gone (HTTP 404)"
      deleted=$((deleted + 1))
    else
      echo "❌ Failed (HTTP ${code})"
      cat /tmp/uddi_delete.json 2>/dev/null || echo "(no response body)"
      failed=$((failed + 1))
    fi
  done
  dur=$(($(date +%s) - start))
  echo "Summary: ${deleted} deleted, ${failed} failed in ${dur}s"
  emit deleted "$deleted"
  emit failed "$failed"
  emit duration "$dur"
  [ "$failed" -gt 0 ] && exit 1
  return 0
}

case "$OP" in
  find-demo-records) find_records ;;
  find-demo-subnets) find_subnets ;;
  delete) delete_resources ;;
  *)
    echo "Unknown operation: ${OP}" >&2
    exit 2
    ;;
esac
