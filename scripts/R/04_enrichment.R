# %% [markdown]
# # 5. Enrichment analysis
#
# - **`standard_ora()`** — over-representation analysis: are the
#   significantly altered metabolites enriched in any metabolite-set Fisher's
#   exact test, the same engine `clusterProfiler` uses.
#

# - **`cluster_ora()`** - requires clutsers of metabolites you obtain from other
# previous analysis (e.g. biological regulated clustering) and tests for
# enrichment of each cluster separately.
# %%

source(file.path(here::here(), "scripts/R/_utils.R"))
library(MetaProViz)
library(OmnipathR)
library(dplyr)

# %% [markdown]
# ## 1. Load the DMA results
# For the same data for which we have prepared the metabolite ID feature space,
# we will load now the differential metabolite results.
# If you need to create differential results first you can use MetaProViz functionality:
# https://saezlab.github.io/MetaProViz/reference/dma.html

# %%

# Load data
data(tissue_dma) # compares tumour versus normal

# %% [markdown]
# ## 2. Load the feature metadata
# Prepared in 02_id_workflow and 03_id_to_pk

# %%

# Load feature table
Tissue_MetaData_Extended_cleaned <- readRDS(file.path(mp_results_dir(), "MetaboliteIDs_expanded_cleanedKEGG.rds"))

# Combine with data
dma_res <- merge( # kegg.y is from old DMA
    x = Tissue_MetaData_Extended_cleaned,
    y = tissue_dma[,1:7],
    by = "Metabolite",
    all = TRUE
)

# Ensure unique IDs and full background --> we include measured features that
# do not have a KEGG ID.
dma_res_clean <-
    dma_res %>%
    select(
        Metabolite,
        KEGG,
        InputID_select,
        Log2FC,
        t.val,
        p.val,
        p.adj
    ) %>%
    mutate(  # make one KEGG column from "KEGG" and "InputID_select"
        KEGG = case_when(
            InputID_select == "KEGG" ~ KEGG,
            .default = InputID_select
        )
    ) %>%
    select(
        - InputID_select
    ) %>%
    mutate(  # mark original rows
        .row_id = row_number()
    ) %>%
    separate_rows(  # make long-format for cases with two KEGG IDs
        KEGG,
        sep = ",\\s*"
    ) %>%
    group_by( # create index per original row
        .row_id
    ) %>%
    mutate(
        .dup_index = row_number(),
        .n = n()
    ) %>%
    ungroup() %>%
    mutate(   #  only add suffix if there was splitting (n > 1)
        Metabolite = if_else(
            .n > 1,
            paste0(Metabolite, "_", .dup_index),
            Metabolite
        )
    ) %>%
    mutate(
        KEGG = if_else(
            is.na(KEGG),
            paste0("NA_", cumsum(is.na(KEGG))),
            KEGG
        )
    ) %>%
    group_by(
        KEGG
    ) %>%
    slice_max(    # For duplicated KEGG IDs --> keep higher absolute Log2FC
        order_by = Log2FC, n = 1, with_ties = FALSE
    ) %>%
    ungroup() %>%
    column_to_rownames(
        "KEGG"
    ) %>%
    rename(
        Metabolite_Name = Metabolite
    ) %>%
    select(
        - ".row_id",
        - ".dup_index",
        - ".n"
    )

# Inspect the dma_res_clean table

# %% [markdown]
# ## 3. Load KEGG pathway-metabolite sets
# We load the cleaned version via MetaProViz (part of MetSigDB)

# %%
kegg_pw <- metsigdb_kegg()
head(kegg_pw)

# As we found some problematic cases we remove those from the PK
KEGG_Pathways_clean <-
    kegg_pw %>%
    filter(
        !(MetaboliteID == "C01087" & term == "Metabolic pathways"),  # Remove (R)-2-Hydroxyglutarate (C01087) from KEGG pathway "Metabolic Pathways"
        !(MetaboliteID == "C00668" & term %in% c(    # C00092, C00668: remove C00668 from Pathways which contain both of them
            "Metabolic pathways",
            "Biosynthesis of secondary metabolites"
        ))
    )

# %% [markdown]
# ## Standard ORA per contrast
#
# `standard_ora()` expects a table with `Metabolite` row names and
# `t.val` / `p.adj` columns — exactly what `dma()` produces.

# %% [markdown]
# Note on ID matching: the toy dataset's `Metabolite` column uses
# trivial names (e.g. `lactate`, `leucine`). Standard pathway resources
# use HMDB or KEGG IDs. In a real workflow you'd translate first via
# `OmnipathR::translate_ids()` or use a dataset-specific mapping. For
# this demo we wrap the call in `tryCatch()` so an empty-overlap result
# does not stop the script.

# %%

set.seed(100)

Res <- standard_ora(
    data = dma_res_clean, # Input data requirements: column `t.val` and column `Metabolite`
    metadata_info = c(
        pvalColumn = "p.adj",
        percentageColumn = "t.val",
        PathwayTerm = "term",
        PathwayFeature = "MetaboliteID"
    ),
    input_pathway = KEGG_Pathways_clean,  # Pathway file requirements: column `term`, `Metabolite` and `Description`. Above we loaded the Kegg_Pathways using MetaProViz::Load_KEGG()
    pathway_name = "KEGG_TvN",
    min_gssize = 3,
    max_gssize = 1000,
    cutoff_stat = 0.01,
    cutoff_percentage = 10
)


# Select to plot:
Res_Select <- Res[["ClusterGosummary"]] %>%
    filter(p.adjust < 0.1)

# Plot Volcano of top altered pathways:
viz_volcano(
    plot_types = "PEA",
    data = dma_res_clean, # Must be the data you have used as an input for the pathway analysis
    data2 = as.data.frame(Res_Select) %>% dplyr::rename("term"="ID"),
    metadata_info = c(
        PEA_Pathway = "term",# Needs to be the same in both, metadata_feature and data2.
        PEA_stat = "p.adjust",#Column data2
        PEA_score = "GeneRatio",#Column data2
        PEA_Feature = "MetaboliteID"
    ), # Column metadata_feature (needs to be the same as row names in data)
    metadata_feature = KEGG_Pathways_clean, #Must be the pathways used for pathway analysis
    plot_name = "KEGG_TvN",
    select_label = NULL,
    subtitle = "PEA"
)

# %% [markdown]
# ## Understand redundancy with `cluster_pk()`
#
# Many pathway resources contain near-duplicate terms. `cluster_pk()`
# clusters terms by their metabolite-set similarity (Jaccard,
# overlap-coefficient, or correlation), then picks one representative
# per cluster.

# %%

cluster_pk_input <- Res[["ClusterGosummary"]] %>%
    filter(pvalue < 0.05)

cluster_pk_res <-
    cluster_pk(
        cluster_pk_input,
        metadata_info = c(
            metabolite_column = "Metabolites_in_pathway",
            pathway_column = "ID"
        ),
        input_format = "enrichment",
        similarity = "jaccard",
        threshold = 0.6,
        plot_threshold = 0.4,
        clust = "community",
        min = 1,
        node_size_column = "percentage_of_Pathway_detected",
        save_plot = NULL,
        plot_name = "Enrichment_example",
        print_plot = FALSE,
        min_degree = 0,
        show_density = TRUE,
        max_nodes = 1000
    )

head(cluster_pk_res$cluster_summary)
cluster_pk_res$graph_plot

set.seed(123)
viz_graph(
    similarity_matrix = cluster_pk_res$similarity_matrix,
    clusters = cluster_pk_res$clusters,
    plot_threshold = 0,
    plot_name = "Enrichment_example_plot_threshold_0",
    max_nodes = 1000,
    min_degree = 0,
    node_sizes = cluster_pk_res$node_sizes,
    show_density = TRUE,
    save_plot = "svg",
    print_plot = FALSE
)


# We could also do this using KEGG before we run enrichment analysis:
clustered_kegg <- cluster_pk(
    data = kegg_pw,
    metadata_info = c(metabolite_column = "MetaboliteID", pathway_column = "term"),
    similarity = "jaccard",
    threshold = 0.5,
    save_plot = NULL,
    print_plot = FALSE,
    path = mp_results_dir("05_enrichment")
)

names(clustered_kegg)
cluster_pk_input <- Res_Select



# %% [markdown]
# **Recap.** Three enrichment angles on the same dma table: raw KEGG ORA,
# de-duplicated KEGG ORA via `cluster_pk()`. Then we
# visualised one of these as a small network.
