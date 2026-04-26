#!/usr/bin/env bash
#
# build_rlib.sh — Build the pre-warmed R library tarball for participants.
#
# Run this on the `beauty` workstation. It:
#   1. Creates a fresh user-library directory and points R at it,
#   2. Installs OmnipathR, MetaProViz, and IRkernel via env/install.R,
#   3. Compresses the resulting tree as rlib.tar.gz.
#
# The output tarball is then uploaded by trainer/upload_rlib.sh.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK_DIR="${TMPDIR:-/tmp}/metabo2026-rlib-$(date +%Y%m%d-%H%M%S)"
LIB_DIR="$WORK_DIR/rlib"
TARBALL="$REPO_ROOT/results/rlib.tar.gz"

mkdir -p "$LIB_DIR"
mkdir -p "$(dirname "$TARBALL")"

echo "[build_rlib] Working in: $WORK_DIR"
echo "[build_rlib] Library dir: $LIB_DIR"

# Install all packages into the isolated library.
R_LIBS_USER="$LIB_DIR" Rscript "$REPO_ROOT/env/install.R"

echo "[build_rlib] Compressing to $TARBALL"
tar -czf "$TARBALL" -C "$LIB_DIR" .

ls -lh "$TARBALL"
echo "[build_rlib] done."
echo "Next: ./upload_rlib.sh"
