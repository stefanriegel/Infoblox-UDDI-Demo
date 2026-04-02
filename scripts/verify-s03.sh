#!/usr/bin/env bash
# S03 Cross-Suite Verification Script
# Validates consistency across all 4 demo workflows
set -euo pipefail

PASS=0; FAIL=0

check() {
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "  ✅ ${desc}"
    PASS=$((PASS + 1))
  else
    echo "  ❌ ${desc}"
    FAIL=$((FAIL + 1))
  fi
}

echo "═══════════════════════════════════════════════"
echo "  S03 Cross-Suite Verification"
echo "═══════════════════════════════════════════════"
echo ""

# ── Check 1: All 4 workflow YAMLs parse ──────────────────────────────
echo "📋 YAML Parsing"
for f in .github/workflows/cleanup.yml .github/workflows/combined-demo.yml .github/workflows/run-demo.yml .github/workflows/vpc-deployment.yml; do
  check "Parse ${f}" python3 -c "import yaml; yaml.safe_load(open('${f}'))"
done
echo ""

# ── Check 2: UDDI Badge in all 4 workflows ──────────────────────────
echo "🏷️  UDDI Branding"
count=$(grep -rl 'Infoblox-Universal_DDI-0066cc' .github/workflows/*.yml | wc -l | tr -d ' ')
check "Badge present in all 4 workflows (found: ${count})" [ "$count" -ge 4 ]
echo ""

# ── Check 3: Combined demo tags ─────────────────────────────────────
echo "🏗️  Combined Demo Tags"
check "ManagedBy tag in combined/main.tf" grep -q 'ManagedBy' live/demos/combined/main.tf
check "Demo tag in combined/main.tf" grep -q 'Demo.*"true"' live/demos/combined/main.tf
echo ""

# ── Check 4: Terraform validates ────────────────────────────────────
echo "🔧 Terraform Validation"
check "combined demo validates" bash -c 'cd live/demos/combined && terraform init -backend=false -no-color >/dev/null 2>&1 && terraform validate -no-color >/dev/null 2>&1'
echo ""

# ── Check 5: Narration present in all workflows ─────────────────────
echo "📖 Narration Boxes"
for f in .github/workflows/run-demo.yml .github/workflows/vpc-deployment.yml .github/workflows/cleanup.yml .github/workflows/combined-demo.yml; do
  check "Narration in $(basename ${f})" grep -q '╔══' "$f"
done
echo ""

# ── Check 6: SE-friendly input descriptions ─────────────────────────
echo "🎯 SE-Friendly Inputs"
check "DNS record_value has examples" grep -q 'e.g.' .github/workflows/run-demo.yml
check "VPC deploy_aws defaults to true" bash -c "python3 -c \"import yaml; d=yaml.safe_load(open('.github/workflows/vpc-deployment.yml')); assert d[True]['workflow_dispatch']['inputs']['deploy_aws']['default'] == True\""
check "VPC deploy_aws has recommended note" grep -q 'recommended' .github/workflows/vpc-deployment.yml
echo ""

# ── Summary ──────────────────────────────────────────────────────────
echo "═══════════════════════════════════════════════"
echo "  Results: ${PASS} passed, ${FAIL} failed"
echo "═══════════════════════════════════════════════"

[ "$FAIL" -eq 0 ]
