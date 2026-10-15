#!/usr/bin/env bash
# setDistOidc.sh — stamp OIDC meta tags into a portable dist/index.html
# Usage:
#   ./scripts/setDistOidc.sh AUTHORITY CLIENT_ID [distDir]
#   ./scripts/setDistOidc.sh '' ''              # login gate OFF
#   ./scripts/setDistOidc.sh 'https://keycloak/realms/master' common
#
# Docker nginx injects the same metas from VITE_OIDC_* via sub_filter.
# Empty authority or client id → AuthGate skips login (same as unset .env).

set -euo pipefail

AUTHORITY_RAW=${1-}
CLIENT_ID_RAW=${2-}
DIST_DIR=${3:-dist}

cd "$(dirname "$0")/.."

INDEX="${DIST_DIR}/index.html"
if [ ! -f "$INDEX" ]; then
  echo "Missing ${INDEX}" >&2
  exit 1
fi

# Trim trailing slashes on authority; leave client id as-is (trimmed).
AUTHORITY=$(printf '%s' "$AUTHORITY_RAW" | sed 's:/*$::' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
CLIENT_ID=$(printf '%s' "$CLIENT_ID_RAW" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

# Escape for HTML attribute + sed replacement delimiter #
html_escape() {
  printf '%s' "$1" | sed -e 's/&/\&amp;/g' -e 's/"/\&quot;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' -e 's/#/\\#/g'
}

AUTH_ESC=$(html_escape "$AUTHORITY")
CLIENT_ESC=$(html_escape "$CLIENT_ID")

META_AUTH="<meta name=\"postgresto-oidc-authority\" content=\"${AUTH_ESC}\">"
META_CLIENT="<meta name=\"postgresto-oidc-client-id\" content=\"${CLIENT_ESC}\">"

# Remove any previous OIDC metas then inject after <head> (or after <base> if present).
# Overwrite in place (do not mv/replace the inode) so bind mounts stay intact.
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
sed -E \
  -e 's#<meta[[:space:]]+name="postgresto-oidc-authority"[^>]*>##g' \
  -e 's#<meta[[:space:]]+name="postgresto-oidc-client-id"[^>]*>##g' \
  "$INDEX" \
  | sed "s#<head>#<head>${META_AUTH}${META_CLIENT}#" \
  >"$tmp"
cat "$tmp" >"$INDEX"

if [ -n "$AUTHORITY" ] && [ -n "$CLIENT_ID" ]; then
  echo "Set OIDC authority=${AUTHORITY} client_id=${CLIENT_ID} in ${INDEX}"
else
  echo "Cleared OIDC meta (login gate OFF) in ${INDEX}"
fi
