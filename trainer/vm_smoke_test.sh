#!/usr/bin/env bash
#
# vm_smoke_test.sh — Reproduce the X11/Helvetica font bug in a clean
# Ubuntu 22.04 container, then verify the .Rprofile fix resolves it.
#
# Run from the repo root. Requires Docker.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

cat <<'NOTE'
[vm_smoke_test] Building a clean ubuntu:22.04 + R-base container and
running two checks:
  1. WITHOUT the repo's .Rprofile  -> expect the X11 font failure
  2. WITH the repo's .Rprofile     -> expect success
NOTE

docker run --rm \
    --name metabo2026-smoke \
    -v "$REPO_ROOT:/repo:ro" \
    ubuntu:22.04 \
    bash -c '
        set -e
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -qq
        apt-get install -y -qq --no-install-recommends r-base libcairo2 fonts-dejavu fonts-liberation libpangocairo-1.0-0 ca-certificates >/dev/null

        echo
        echo "==[ 1. Without .Rprofile — expect X11 font error ]=="
        cd /tmp
        unset DISPLAY
        Rscript --no-init-file -e "
            options(bitmapType = \"Xlib\")
            grDevices::pdf(NULL)
            tryCatch(
                grid::stringMetric(\"x\"),
                error = function(e) message(\"REPRODUCED: \", conditionMessage(e))
            )
        " || true

        echo
        echo "==[ 2. With .Rprofile — expect success ]=="
        cd /repo
        Rscript -e "
            grid::stringMetric(\"x\")
            cat(\"PASSED: stringMetric returned without error\\n\")
        "
    '

echo
echo "[vm_smoke_test] Done."
