#!/usr/bin/env bash
# setDistBasePath.sh — stamp <base href> into a portable dist/index.html
# Usage:
#   ./scripts/setDistBasePath.sh /my/mount [distDir]
#   ./scripts/setDistBasePath.sh /          # site root
#
# Needed when hosting outside docker/nginx (which injects <base> itself).
# Deep SPA routes require an absolute <base href> so ./assets/* resolve
# from the mount path, not the current URL segment.

set -euo pipefail

BASE_RAW=${1:?Usage: $0 /mount/path [distDir]}
DIST_DIR=${2:-dist}

cd "$(dirname "$0")/.."

INDEX="${DIST_DIR}/index.html"
if [ ! -f "$INDEX" ]; then
  echo "Missing ${INDEX}" >&2
  exit 1
fi

# Normalize to "/path/" or "/"
BASE=$(printf '%s' "$BASE_RAW" | sed 's:/*$::')
if [ -z "$BASE" ] || [ "$BASE" = "/" ]; then
  HREF="/"
else
  case "$BASE" in
    /*) HREF="${BASE}/" ;;
    *) HREF="/${BASE}/" ;;
  esac
fi

# Remove any previous <base ...> then inject after <head>.
# Overwrite in place (do not mv/replace the inode) so bind mounts and
# existing mode/owner stay intact — a replace can leave 0600 and nginx 403s.
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
sed -E 's#<base[[:space:]][^>]*>##g' "$INDEX" \
  | sed "s#<head>#<head><base href=\"${HREF}\">#" \
  >"$tmp"
cat "$tmp" >"$INDEX"

echo "Set <base href=\"${HREF}\"> in ${INDEX}"
