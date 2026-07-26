#!/usr/bin/env bash
#
# Build a NoCloud cloud-init seed ISO for a NIOS-X server.
#
# The ISO carries the user-data documented by Infoblox for KVM deployments
# (host_setup.jointoken) and is attached to the cloned VM as a CD-ROM. The
# volume label must be CIDATA for cloud-init's NoCloud datasource to find it.
#
# Usage:
#   NIOSX_JOIN_TOKEN=<token> ./scripts/build-niosx-seed.sh [--hostname NAME] [--out PATH]
#
# Env:
#   NIOSX_JOIN_TOKEN      required - join token from the Infoblox Portal
#   NIOSX_HTTPS_PROXY     optional - sets host_setup.access_https_proxy
#
set -euo pipefail

HOSTNAME_ARG="niosx-demo"
OUT="seed.iso"

while [ $# -gt 0 ]; do
  case "$1" in
    --hostname) HOSTNAME_ARG="$2"; shift 2 ;;
    --out)      OUT="$2"; shift 2 ;;
    -h|--help)  sed -n '2,17p' "$0"; exit 0 ;;
    *)          echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

if [ -z "${NIOSX_JOIN_TOKEN:-}" ]; then
  echo "error: NIOSX_JOIN_TOKEN is not set" >&2
  exit 1
fi

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT
mkdir -p "$WORKDIR/cidata"

{
  echo "#cloud-config"
  echo "host_setup:"
  echo "  jointoken: ${NIOSX_JOIN_TOKEN}"
  if [ -n "${NIOSX_HTTPS_PROXY:-}" ]; then
    echo "  access_https_proxy: ${NIOSX_HTTPS_PROXY}"
  fi
  echo "  tags:"
  echo "    - demo=true"
  echo "    - automation=github-actions"
  echo "    - hostname=${HOSTNAME_ARG}"
} > "$WORKDIR/cidata/user-data"

# No network-config file: the server picks up DHCP on the tagged VLAN.
cat > "$WORKDIR/cidata/meta-data" <<EOF
instance-id: ${HOSTNAME_ARG}-$(date +%s)
local-hostname: ${HOSTNAME_ARG}
EOF

# cloud-localds on CI runners, hdiutil on macOS, genisoimage/xorriso elsewhere.
if command -v cloud-localds >/dev/null 2>&1; then
  cloud-localds "$OUT" "$WORKDIR/cidata/user-data" "$WORKDIR/cidata/meta-data"
elif command -v genisoimage >/dev/null 2>&1; then
  genisoimage -quiet -output "$OUT" -volid CIDATA -joliet -rock "$WORKDIR/cidata"
elif command -v xorriso >/dev/null 2>&1; then
  xorriso -as genisoimage -quiet -output "$OUT" -volid CIDATA -joliet -rock "$WORKDIR/cidata"
elif command -v hdiutil >/dev/null 2>&1; then
  hdiutil makehybrid -iso -joliet -default-volume-name CIDATA -o "$OUT" "$WORKDIR/cidata" >/dev/null
else
  echo "error: need one of cloud-localds, genisoimage, xorriso or hdiutil" >&2
  exit 1
fi

# hdiutil appends .iso when the name lacks it; normalise so Terraform finds it.
if [ ! -f "$OUT" ] && [ -f "${OUT}.iso" ]; then
  mv "${OUT}.iso" "$OUT"
fi

# Fail loudly rather than uploading an ISO cloud-init will ignore.
[ -s "$OUT" ] || { echo "error: $OUT was not created" >&2; exit 1; }
if command -v file >/dev/null 2>&1 && ! file "$OUT" | grep -q CIDATA; then
  echo "error: $OUT is missing the CIDATA volume label" >&2
  exit 1
fi

echo "built $OUT ($(wc -c < "$OUT" | tr -d ' ') bytes) for host ${HOSTNAME_ARG}"
