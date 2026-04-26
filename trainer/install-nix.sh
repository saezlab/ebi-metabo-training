#!/usr/bin/env bash
#
# trainer/install-nix.sh — NixOS-friendly R install for the metabo2026
# training repo.
#
# Run from the repo root. Wraps `remotes::install_github(upgrade = "never")`
# inside `nix-shell` with the C dev headers MetaProViz / OmnipathR need at
# compile time, so the deep Bioconductor dep tree comes from `/nix/store`
# (instant) and only the two saezlab packages source-compile (~3-5 min).
#
# This is what `env/install.R` redirects to when it detects NixOS.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Resolve the canonical R user library for the current R version.
USER_LIB=$(Rscript --vanilla -e 'cat(file.path(Sys.getenv("HOME"), "R", paste0(R.version$platform, "-library"), sprintf("%s.%s", R.version$major, sub("\\.[0-9]+$", "", R.version$minor))))')

mkdir -p "$USER_LIB"
echo "[install-nix] R user library: $USER_LIB"

nix-shell \
    -p curl libuv openssl libxml2 libgit2 libssh2 libpng \
       cairo pango glib harfbuzz fribidi freetype fontconfig \
       icu bzip2 xz pkg-config gcc \
    --run "
        Rscript --vanilla -e '
            user_lib <- \"$USER_LIB\"
            .libPaths(c(user_lib, .libPaths()))
            options(repos = c(CRAN = \"https://cloud.r-project.org\"))
            for (p in c(\"remotes\", \"here\", \"IRkernel\")) {
                if (!requireNamespace(p, quietly = TRUE)) {
                    install.packages(p, lib = user_lib)
                }
            }
            for (pkg in c(\"saezlab/OmnipathR\", \"saezlab/MetaProViz\")) {
                cat(\"\\n=== \", pkg, \" ===\\n\")
                remotes::install_github(pkg, upgrade = \"never\",
                                        lib = user_lib, dependencies = TRUE)
            }
            try(IRkernel::installspec(name = \"ir-metabo2026\",
                                      displayname = \"R (metabo2026)\",
                                      user = TRUE), silent = TRUE)
            cat(\"\\nInstall complete.\\n\")
        '
    "
