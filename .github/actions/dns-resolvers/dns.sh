#!/usr/bin/env bash
# Query a record against the public resolvers once, with a single definition of
# the resolver set and the empty-answer fallback. Narration goes to the log; the
# presented job summary stays in the calling workflow (writes dig-<label>.txt for
# it, and exposes short answers as outputs). See docs/adr/0003-*.
set -euo pipefail

FQDN="${FQDN:?FQDN required}"
TYPE="${RECORD_TYPE:-A}"
OUT_DIR="${OUTPUT_DIR:-}"
RESOLVERS="${RESOLVERS:-google:8.8.8.8 cloudflare:1.1.1.1 quad9:9.9.9.9}"

NO_ANSWER="(no answer yet - DNS propagation in progress)"

emit() { [ -n "${GITHUB_OUTPUT:-}" ] && printf '%s\n' "$1" >> "$GITHUB_OUTPUT"; return 0; }

echo "============================================"
echo "🔍 DNS VERIFICATION — ${FQDN} (${TYPE})"
echo "============================================"

answers='{}'
for pair in $RESOLVERS; do
  label="${pair%%:*}"
  ip="${pair#*:}"
  cap="$(printf '%s' "${label:0:1}" | tr '[:lower:]' '[:upper:]')${label:1}"

  # Join multi-value answers onto one line — GITHUB_OUTPUT key=value is single-line.
  short=$(dig +short -t "$TYPE" "$FQDN" @"$ip" 2>/dev/null | paste -sd, - || true)
  answer=$(dig +nocmd +noall +answer -t "$TYPE" "$FQDN" @"$ip" 2>/dev/null || true)

  echo ""
  echo "📡 ${cap} DNS (${ip}):"
  if [ -n "$answer" ]; then echo "$answer"; else echo "   ${NO_ANSWER}"; fi

  if [ -n "$OUT_DIR" ]; then
    if [ -n "$answer" ]; then
      printf '%s\n' "$answer" > "${OUT_DIR}/dig-${label}.txt"
    else
      printf '%s\n' "$NO_ANSWER" > "${OUT_DIR}/dig-${label}.txt"
    fi
  fi

  emit "${label}=${short}"
  answers=$(jq -c --arg k "$label" --arg v "$short" '. + {($k): $v}' <<<"$answers")
done

if [ -n "$OUT_DIR" ]; then
  dig "$FQDN" "$TYPE" @8.8.8.8 > "${OUT_DIR}/dig-full.txt" 2>/dev/null || true
fi

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  {
    echo "answers<<__EOF__"
    echo "$answers"
    echo "__EOF__"
  } >> "$GITHUB_OUTPUT"
fi
