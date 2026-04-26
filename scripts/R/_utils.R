# scripts/R/_utils.R
#
# Small helpers shared by the training scripts. Loaded at the top of each
# numbered script via `source(file.path(here::here(), "scripts/R/_utils.R"))`.

suppressPackageStartupMessages({
    library(SummarizedExperiment)
    library(dplyr)
    library(tibble)
    library(stringr)
})

# Repository root regardless of where the script was sourced from.
mp_repo_root <- function() {
    if (requireNamespace("here", quietly = TRUE)) return(here::here())
    # Fallback: walk up from the script directory until we find env/install.R.
    start <- if (sys.nframe() > 0) {
        normalizePath(dirname(sys.frame(1)$ofile %||% "."), mustWork = FALSE)
    } else {
        getwd()
    }
    candidate <- start
    for (i in 1:6) {
        if (file.exists(file.path(candidate, "env", "install.R"))) return(candidate)
        candidate <- dirname(candidate)
    }
    getwd()
}

# results/ directory used by save_plot / save_table calls.
mp_results_dir <- function(subdir = NULL) {
    out <- file.path(mp_repo_root(), "results")
    if (!is.null(subdir)) out <- file.path(out, subdir)
    dir.create(out, showWarnings = FALSE, recursive = TRUE)
    out
}

# Convenience NULL-coalesce.
`%||%` <- function(a, b) if (!is.null(a)) a else b

# Compact head() for notebook display: rows × first n columns.
mp_peek <- function(x, n_rows = 6L, n_cols = 8L) {
    if (inherits(x, "SummarizedExperiment")) {
        cat("SummarizedExperiment:", nrow(x), "features x", ncol(x), "samples\n")
        cat("Assays:", paste(SummarizedExperiment::assayNames(x), collapse = ", "), "\n")
        return(invisible(x))
    }
    if (is.data.frame(x) || is.matrix(x)) {
        return(head(x[, seq_len(min(ncol(x), n_cols)), drop = FALSE], n_rows))
    }
    head(x, n_rows)
}
