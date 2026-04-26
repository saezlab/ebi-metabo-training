#!/usr/bin/env bash
#
# upload_rlib.sh — Push the locally-built rlib.tar.gz to the public static host.
#
# Assumes the script runs on `beauty`, where the static.omnipathdb.org
# webroot is locally mounted at /srv/static (adjust if the path differs).
#
# Override the destination via the STATIC_DEST env var if needed.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARBALL="$REPO_ROOT/results/rlib.tar.gz"
STATIC_DEST="${STATIC_DEST:-/srv/static/metabo2026/}"

if [[ ! -f "$TARBALL" ]]; then
    echo "[upload_rlib] Tarball not found at $TARBALL — run build_rlib.sh first." >&2
    exit 1
fi

mkdir -p "$STATIC_DEST"
cp -v "$TARBALL" "$STATIC_DEST/rlib.tar.gz"

echo "[upload_rlib] Uploaded $(du -h "$TARBALL" | cut -f1) to $STATIC_DEST"
echo "[upload_rlib] Public URL: https://static.omnipathdb.org/metabo2026/rlib.tar.gz"
