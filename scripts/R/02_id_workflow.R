# %% [markdown]
# # 2. MetaProViz Metabolite ID workflow
# This is important to improving the connection between prior knowledge and
# metabolomics features.
# Many databases that collect metabolite information, such as the Human
# Metabolome Database (HMDB), include multiple entries for the same metabolite
# with different degrees of ambiguity. This poses a difficulty when assigning
# metabolite IDs to measured data where e.g. stereoisomers are not distinguished.
# Hence, if detection is unspecific, it is crucial to assign all possible
# IDs to increase the overlap with the prior knowledge.
# MetaProViz offers methodologies to solve such conflicts to allow robust mapping
# of experimental data with prior knowledge. In detail, MetaProViz performs
# feature space quality control, offers functionalities to increase the
# metabolite ID feature space, including ID translation, ID traversion through
# a metabolite ID graph and enantiomer addition and quantifies mapping ambiguities.
# this is the workflow we will follow in the next steps.

# %%
source(file.path(here::here(), "scripts/R/_utils.R"))
library(MetaProViz)

# dependencies that need to be loaded:
library(magrittr)
library(dplyr)
library(rlang)
library(tidyr)
library(tibble)
library(stringr)

# establish helper functions to create some overview summaries that we can use to
# discuss the individual steps we will be doing within this workflow:

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


# %% [markdown]
# ## Feature space quality control
#
# Analyse the existent metabolite ID space using MetaProViz `compare_pk()`
# function to check the overlap of the different ID types and the coverage of
# the feature space and `count_id()`.

# %%

# Load cleaned feature metadata with unified ID separator
MetaboliteIDs <- readRDS(file.path(mp_results_dir(), "MetaboliteIDs_clean_idseparator.rds"))

# compare id space
ccRCC_CompareIDs <- compare_pk(data = list(Biocft = MetaboliteIDs |>
                                               dplyr::rename("Class"="SUPER_PATHWAY")),
                               name_col = "Metabolite",
                               metadata_info = list(Biocft = c("KEGG", "HMDB", "PUBCHEM")),
                               plot_name = "Overlap of ID types in ccRCC data")

# %% [markdown]
# Here we notice that 76 features have no metabolite ID assigned, yet have a
# trivial name and a metabolite class assigned. For 135 metabolites we only
# have a pubchem ID, yet no HMDB or KEGG ID. Only 43% of all features have HMDB,
# KEGG and Pubchem IDs assigned, whilst 23% only had a PubChem ID assigned.
# One explanation could be that the databases covered less structures when the
# study was published in 2016.

# %%

#count ids
# 1. HMDB:
Plot1_HMDB <- count_id(MetaboliteIDs,
                       delimiter = ", ",
                       "HMDB")

# The output is a data table that is visualized in a barplot
head(Plot1_HMDB[["Table"]])
Plot1_HMDB[["Plot_Sized"]]

# 2. KEGG:
Plot1_KEGG <- count_id(MetaboliteIDs,
                       delimiter = ", ",
                       "KEGG")

# 3. PubChem:
Plot1_PubChem <- count_id(MetaboliteIDs,
                          delimiter = ", ",
                          "PUBCHEM")


# %% [markdown]
# Now we can extract some summary statistics from the count_id() output to get a
# better overview of the ID space and how it changes with the different steps of
# the workflow. For this we use our helper functions established at the start of
# the script.

# This table stores one row per database and category, for example:
# HMDB_Original, KEGG_cleaned, PUBCHEM_Original, etc.
#
# Column meanings:
# no_ID         = number of features with no ID in that database
# Single_ID     = number of features with exactly one ID in that database
# Multiple_IDs  = number of features with more than one ID in that database
# Total_IDs     = total number of IDs assigned in that database
#                 calculated as sum(entry_count)

# %%

id_count_df <- tibble(
    row_name      = character(),
    no_ID         = integer(),
    Single_ID     = integer(),
    Multiple_IDs  = integer(),
    Total_IDs     = integer()
)

id_count_df <- append_id_counts(id_count_df, Plot1_HMDB,    "HMDB_Original")
id_count_df <- append_id_counts(id_count_df, Plot1_KEGG,    "KEGG_Original")
id_count_df <- append_id_counts(id_count_df, Plot1_PubChem, "PUBCHEM_Original")

head(id_count_df)


# %% [markdown]
# Part of the ID QC is also to check the MetaboliteOD compatibility. This checks
# for ID mismatches of features with metabolite IDs that pointed to different
# metabolite structures.

# %%

# Note: The input df does not contain ChEBI IDs. For the compatibility check,
# ChEBI IDs are internally used as possible stepstones for ID compatibility
MetaboliteIDs_compatibility_check <- seed_id_compatibility_check(
    data = MetaboliteIDs,
    id_types = c("HMDB", "KEGG", "CHEBI", "PUBCHEM"),
    delimiter = ","
)


# %% [markdown]
# here we:
# removed 41 partially incompatible cases (= some IDs are connected in the network
# whilst others are not)
# 33 cases with no match between IDs (=fully incompatible) --> manual review
# required. Here we only look at one example, but ignore those as we do not
# have the time for a manual review in this session.

# %% [markdown]


# %%

# %%
saveRDS(dma_results, file.path(mp_results_dir(), "dma_results.rds"))

# %% [markdown]
# **Recap.** `dma()` produced three contrasts (`*_vs_HK2`). Volcano +
# heatmap + PCA give us a quick read on biology before we move to
# pathway-level interpretation in scripts 03-05.
