# env/install.R
#
# One-shot R installation for the EMBL-EBI 2026 metabolomics training.
#
# Strategy, in order of preference:
#
#   1. Ubuntu/Debian/RHEL/Rocky/Alma + macOS + Windows -> binary packages
#      from Posit Public Package Manager (PPM) via pak. Fast (~3-5 min).
#   2. NixOS -> exit with a pointer to `trainer/install-nix.sh`, which
#      uses nixpkgs Bioconductor binaries + `remotes::install_github`.
#   3. Other Linux distros (Arch, Alpine, …) -> emit a slow-path warning
#      and source-compile from CRAN (~15-25 min).
#
# Always installs into the user's writable R library (`R_LIBS_USER`);
# never tries to write to a system library.

# ---- Probe /etc/os-release ----
read_os_release <- function() {
    if (!file.exists("/etc/os-release")) return(list())
    lines <- readLines("/etc/os-release", warn = FALSE)
    out <- list()
    for (key in c("ID", "ID_LIKE", "VERSION_CODENAME")) {
        line <- grep(sprintf("^%s=", key), lines, value = TRUE)[1]
        out[[key]] <- if (is.na(line)) NA_character_ else
            sub(sprintf('^%s="?([^"]*)"?$', key), "\\1", line)
    }
    out
}

os <- read_os_release()
is_linux <- .Platform$OS.type == "unix" && Sys.info()[["sysname"]] == "Linux"

# ---- (2) NixOS short-circuit ----
if (is_linux && identical(os$ID, "nixos")) {
    cat("\n", strrep("=", 64), "\n", sep = "")
    cat("NixOS detected.\n\n")
    cat("Pak + PPM is the wrong tool here: PPM ships .deb-style binaries\n")
    cat("that don't link against /nix/store libs, and pak insists on\n")
    cat("upgrading every existing nixpkgs R package.\n\n")
    cat("Use the Nix-aware installer instead:\n\n")
    cat("    bash trainer/install-nix.sh\n\n")
    cat("That wraps `remotes::install_github(... upgrade = \"never\")` in\n")
    cat("`nix-shell` with the right C dev headers, leveraging the deep\n")
    cat("Bioconductor dep tree pre-built in /nix/store.\n")
    cat(strrep("=", 64), "\n", sep = "")
    quit(save = "no", status = 1)
}

# ---- (1) and (3) Pick the CRAN repo URL ----
ppm_linux_codename <- function(os) {
    id <- os$ID %||% ""
    if (!id %in% c("ubuntu", "debian", "rhel", "centos", "rocky", "almalinux")) {
        return(NULL)
    }
    cn <- os$VERSION_CODENAME %||% ""
    if (!nzchar(cn)) return(NULL)
    cn
}
`%||%` <- function(a, b) if (is.null(a) || is.na(a) || !nzchar(a)) b else a

distro <- if (is_linux) ppm_linux_codename(os) else NULL

if (!is.null(distro)) {
    cran_repo <- sprintf("https://p3m.dev/cran/__linux__/%s/latest", distro)
} else if (is_linux) {
    # Other Linux distros — warn the user this will be slow.
    message("\n--- Slow-install warning ---")
    message("Your Linux distro (ID=", os$ID, ") is not on PPM's binary list.")
    message("All packages will be source-compiled from CRAN. Expect 15-25 min.")
    message("If this is undesirable, install R from your distro's repos and")
    message("rerun, or switch to a supported distro (Ubuntu/Debian/RHEL).")
    message("---")
    cran_repo <- "https://cloud.r-project.org"
} else {
    # macOS / Windows — PPM serves platform binaries from the same URL with
    # the right HTTPUserAgent (set below).
    cran_repo <- "https://p3m.dev/cran/latest"
}

options(
    repos = c(
        CRAN = cran_repo,
        BioC = "https://packagemanager.posit.co/bioconductor"
    ),
    # Setting HTTPUserAgent is what makes PPM serve binaries on Linux.
    HTTPUserAgent = sprintf(
        "R/%s R (%s)",
        getRversion(),
        paste(getRversion(), R.version$platform, R.version$arch, R.version$os)
    ),
    Ncpus = max(1, parallel::detectCores() - 1)
)

# ---- Ensure a writable user library ----
user_lib <- Sys.getenv("R_LIBS_USER", unset = "")
if (!nzchar(user_lib)) {
    user_lib <- file.path(
        Sys.getenv("HOME"),
        "R",
        paste0(R.version$platform, "-library"),
        sprintf("%s.%s", R.version$major, sub("\\.[0-9]+$", "", R.version$minor))
    )
}
dir.create(user_lib, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(user_lib, .libPaths()))

cat("CRAN repo:   ", getOption("repos")[["CRAN"]], "\n", sep = "")
cat("Bioc repo:   ", getOption("repos")[["BioC"]], "\n", sep = "")
cat("Install lib: ", user_lib, "\n", sep = "")

# ---- pak: fast resolver and installer ----
if (!requireNamespace("pak", quietly = TRUE)) {
    install.packages(
        "pak",
        lib = user_lib,
        repos = sprintf(
            "https://r-lib.github.io/p/pak/stable/%s/%s/%s",
            .Platform$pkgType, R.Version()$os, R.Version()$arch
        )
    )
}

# ---- Install ----
# OmnipathR and MetaProViz pulled from GitHub: until the May 2026 Bioc release
# the Bioc devel mirror lags GitHub by a couple of versions, and MetaProViz in
# particular has not yet hit Bioc release.
#
# R.matlab is in OmnipathR's Suggests (via `recon3d_*`); pak only pulls
# hard deps by default. List it here so script 04 (prior_knowledge) can
# load Recon3D without a missing-namespace error.
pkgs <- c(
    "saezlab/OmnipathR",
    "saezlab/MetaProViz",
    "R.matlab",
    "IRkernel"
)

cat("Installing:\n  ", paste(pkgs, collapse = "\n  "), "\n", sep = "")

pak::pkg_install(pkgs, lib = user_lib, upgrade = FALSE, ask = FALSE)

# Sanity check: if IRkernel didn't install, the R notebook won't work.
# pak emits a non-fatal warning when the system has no `libzmq3-dev`
# (needed by pbdZMQ → IRkernel), so a missing IRkernel here means
# either libzmq3-dev is absent or the install was interrupted.
if (!requireNamespace("IRkernel", quietly = TRUE)) {
    msg <- paste0(
        "\n",
        strrep("=", 64), "\n",
        "WARNING: IRkernel did not install.\n",
        "Most likely the system package `libzmq3-dev` is missing.\n",
        "Ask your sysadmin to run, or run yourself if you have sudo:\n\n",
        "    sudo apt-get install -y libzmq3-dev\n\n",
        "Then re-run this script. The R notebook (notebooks/metabo_R.ipynb)\n",
        "will not work without IRkernel.\n",
        strrep("=", 64), "\n"
    )
    message(msg)
}

# We do NOT call IRkernel::installspec() here. On a fresh VM, jupyter
# isn't on PATH yet (it lives inside the uv venv we create in the
# Python install step). The kernel registration is a separate step,
# run from inside the venv via `make register-r-kernel`.

cat("\nInstall complete.\n")
cat("Verify with:  Rscript -e 'library(MetaProViz); library(OmnipathR)'\n")
cat("Next steps:\n")
cat("  1. cd env && uv sync                 # set up Python\n")
cat("  2. make register-r-kernel            # register R for Jupyter\n")
