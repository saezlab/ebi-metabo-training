# env/install.R
#
# One-shot R installation for the EMBL-EBI 2026 metabolomics training.
#
# Pulls binary packages from Posit Public Package Manager (PPM) so the
# install completes in ~3-5 min on a typical Linux/macOS/Windows box,
# instead of the ~20+ min source compile of OmnipathR + MetaProViz.
#
# If PPM is unreachable (locked-down VM network), see docs/01_setup_r.md
# for the pre-built RLIB tarball recovery path.

# ---- Repos: PPM binaries for CRAN + Bioconductor ----
# Detect platform tag for PPM Linux binary URL.
ppm_linux_distro <- function() {
    if (file.exists("/etc/os-release")) {
        os <- readLines("/etc/os-release")
        codename <- sub('^VERSION_CODENAME=("?)(.*)\\1$', "\\2",
                                            grep("^VERSION_CODENAME=", os, value = TRUE))
        if (length(codename) && nzchar(codename)) return(codename)
    }
    "jammy"  # Ubuntu 22.04 default
}

if (.Platform$OS.type == "unix" && Sys.info()[["sysname"]] == "Linux") {
    cran_repo <- sprintf(
        "https://p3m.dev/cran/__linux__/%s/latest",
        ppm_linux_distro()
    )
} else {
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

cat("Using CRAN repo: ", getOption("repos")[["CRAN"]], "\n", sep = "")
cat("Using Bioc repo: ", getOption("repos")[["BioC"]], "\n", sep = "")

# ---- pak: fast resolver and installer ----
if (!requireNamespace("pak", quietly = TRUE)) {
    install.packages(
        "pak",
        repos = sprintf("https://r-lib.github.io/p/pak/stable/%s/%s/%s",
                                        .Platform$pkgType, R.Version()$os, R.Version()$arch)
    )
}

# ---- Install ----
# OmnipathR and MetaProViz pulled from GitHub: until the May 2026 Bioc release
# the Bioc devel mirror lags GitHub by a couple of versions, and MetaProViz in
# particular has not yet hit Bioc release.
pkgs <- c(
    "saezlab/OmnipathR",
    "saezlab/MetaProViz",
    "IRkernel"
)

cat("Installing:\n  ", paste(pkgs, collapse = "\n  "), "\n", sep = "")

pak::pkg_install(pkgs, upgrade = FALSE, ask = FALSE)

# Register the IRkernel for Jupyter so notebooks/metabo_R.ipynb can run.
if (requireNamespace("IRkernel", quietly = TRUE)) {
    try(IRkernel::installspec(name = "ir-metabo2026",
                                                        displayname = "R (metabo2026)",
                                                        user = TRUE),
            silent = TRUE)
}

cat("\nInstall complete.\n")
cat("Verify with:  Rscript -e 'library(MetaProViz); library(OmnipathR)'\n")
