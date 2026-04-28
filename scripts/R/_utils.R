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

# Establish helper functions to create some overview summaries that we can use to
# discuss the individual steps we will be doing within 02_id_workflow.R:

# 1. Helper: extract one summary row from count_id() output
extract_id_counts <- function(count_obj, row_name) {
    ## count_obj must be an object returned by MetaProViz::count_id()

    tbl <- count_obj$Table

    ## Count how many features fall into each ID class
    counts_wide <- tbl %>%
        count(id_label, name = "n") %>%
        mutate(
            id_label = recode(
                id_label,
                "No ID" = "no_ID",
                "Single ID" = "Single_ID",
                "Multiple IDs" = "Multiple_IDs"
            )
        ) %>%
        pivot_wider(
            names_from = id_label,
            values_from = n,
            values_fill = 0
        )

    ## Make sure all expected columns exist
    ## This avoids errors if one class is absent in a given dataset
    for (col in c("no_ID", "Single_ID", "Multiple_IDs")) {
        if (!col %in% names(counts_wide)) {
            counts_wide[[col]] <- 0L
        }
    }

    ## Build one clean summary row
    tibble(
        row_name = row_name,
        no_ID = as.integer(counts_wide$no_ID[1]),
        Single_ID = as.integer(counts_wide$Single_ID[1]),
        Multiple_IDs = as.integer(counts_wide$Multiple_IDs[1]),
        Total_IDs = as.integer(sum(tbl$entry_count, na.rm = TRUE))
    )
}



# 2. Helper: append one summary row to id_count_df
append_id_counts <- function(df, count_obj, row_name) {
    bind_rows(df, extract_id_counts(count_obj, row_name))
}

# 3. Helper: calculate deltas within each database only
calculate_id_deltas <- function(df, from_category, to_category) {

    df %>%
        separate(row_name, into = c("id_type", "category"), sep = "_", remove = FALSE) %>%
        select(-row_name) %>%
        pivot_wider(
            names_from = category,
            values_from = c(no_ID, Single_ID, Multiple_IDs, Total_IDs)
        ) %>%
        transmute(
            row_name = paste0("delta_", id_type, "_", from_category, "_", id_type, "_", to_category),
            no_ID = .data[[paste0("no_ID_", to_category)]] - .data[[paste0("no_ID_", from_category)]],
            Single_ID = .data[[paste0("Single_ID_", to_category)]] - .data[[paste0("Single_ID_", from_category)]],
            Multiple_IDs = .data[[paste0("Multiple_IDs_", to_category)]] - .data[[paste0("Multiple_IDs_", from_category)]],
            Total_IDs = .data[[paste0("Total_IDs_", to_category)]] - .data[[paste0("Total_IDs_", from_category)]]
        )
}

# 4. Helper: count features with no HMDB, KEGG, or PUBCHEM. This works on the
#original category dataframe, not on count_id() output.
count_none_all_ids <- function(df) {
    sum(
        (is.na(df$HMDB)    | trimws(as.character(df$HMDB)) %in% c("", "NA")) &
            (is.na(df$KEGG)    | trimws(as.character(df$KEGG)) %in% c("", "NA")) &
            (is.na(df$PUBCHEM) | trimws(as.character(df$PUBCHEM)) %in% c("", "NA")),
        na.rm = TRUE
    )
}

# 5. Helper: append one row to none_summary_df
append_none_summary <- function(df, input_df, row_name) {
    bind_rows(
        df,
        tibble(
            row_name = row_name,
            No_database_ID = as.integer(count_none_all_ids(input_df))
        )
    )
}

# 6. Helper: calculate delta for the "none at all" summary
calculate_none_delta <- function(df, from_category, to_category) {

    tibble(
        row_name = paste0("delta_", from_category, "_", to_category),
        No_database_ID =
            df$No_database_ID[df$row_name == to_category] -
            df$No_database_ID[df$row_name == from_category]
    )
}


