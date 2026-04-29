# %% [markdown]
# # 5. Enrichment analysis
#
# - **`standard_ora()`** — over-representation analysis: are the
#   significantly altered metabolites enriched in any metabolite-set Fisher's
#   exact test, the same engine `clusterProfiler` uses.

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

data(tissue_dma) # compares tumour versus normal

# %% [markdown]
# ## 2. Load the feature metadata
# Prepared in 02_id_workflow and 03_id_to_pk

# %%
Tissue_MetaData_Extended_cleaned <- readRDS(file.path(mp_results_dir(), "Tissue_MetaData_Extended_cleaned.rds"))

# %% [markdown]
# ## 3. Load KEGG pathway-metabolite sets
# We load the cleaned version via MetaProViz (part of MetSigDB)

# %%
kegg_pw <- metsigdb_kegg()
head(kegg_pw)

# As we found some problematic cases we remove those from the PK
KEGG_Pathways_clean <-
    KEGG_Pathways %>%
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




# %% [markdown]
# ## Reduce redundancy with `cluster_pk()`
#
# Many pathway resources contain near-duplicate terms. `cluster_pk()`
# clusters terms by their metabolite-set similarity (Jaccard,
# overlap-coefficient, or correlation), then picks one representative
# per cluster.

# %%
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



# %% [markdown]
# **Recap.** Three enrichment angles on the same dma table: raw KEGG ORA,
# de-duplicated KEGG ORA via `cluster_pk()`. Then we
# visualised one of these as a small network.
