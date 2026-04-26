# %% [markdown]
# # 5. Enrichment analysis
#
# Two complementary approaches:
#
# - **`standard_ora()`** — over-representation analysis: are the
#   significantly altered metabolites enriched in any pathway? Fisher's
#   exact test, the same engine `clusterProfiler` uses.
# - **`cluster_pk()`** (new in v3.99.40) — first cluster pathway terms
#   that share metabolites, then run ORA on representative clusters.
#   Cuts redundancy in the output (e.g. you get one "TCA cycle"
#   cluster instead of three near-duplicate KEGG/Reactome/Hallmark
#   variants).

# %%
source(file.path(here::here(), "scripts/R/_utils.R"))
library(MetaProViz)
library(OmnipathR)
library(dplyr)

dma_results <- readRDS(file.path(mp_results_dir(), "dma_results.rds"))

# %% [markdown]
# ## Build a pathway resource — KEGG via MetaProViz

# %%
kegg_pw <- metsigdb_kegg()
head(kegg_pw)

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
ora_results <- list()

for (contrast in names(dma_results$dma)) {
    dma_tab <- dma_results$dma[[contrast]] |>
        tibble::column_to_rownames("Metabolite")

    ora_results[[contrast]] <- tryCatch(
        standard_ora(
            data = dma_tab,
            metadata_info = c(
                pvalColumn = "p.adj",
                percentageColumn = "t.val",
                PathwayTerm = "term",
                PathwayFeature = "Metabolite"
            ),
            input_pathway = kegg_pw,
            pathway_name = "KEGG",
            cutoff_stat = 0.05,
            cutoff_percentage = 10,
            min_gssize = 3,
            max_gssize = 1000,
            save_table = NULL,
            path = mp_results_dir("05_enrichment")
        ),
        error = function(e) {
            message("ORA skipped for ", contrast, ": ", conditionMessage(e))
            NULL
        }
    )
}

# %%
if (!is.null(ora_results[["786-M1A_vs_HK2"]])) {
    head(ora_results[["786-M1A_vs_HK2"]]$ClusterGosummary)
}

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
# ## Chemical-class enrichment (added v2.1.4)
#
# The same ORA machinery runs against chemical classes — useful when
# pathway annotation is sparse but compound-class info is rich.

# %%
chem_pk <- metsigdb_chemicalclass()
head(chem_pk)

# %%
ora_chem <- tryCatch(
    standard_ora(
        data = dma_results$dma[["786-M1A_vs_HK2"]] |> tibble::column_to_rownames("Metabolite"),
        metadata_info = c(
            pvalColumn = "p.adj",
            percentageColumn = "t.val",
            PathwayTerm = "term",
            PathwayFeature = "Metabolite"
        ),
        input_pathway = chem_pk,
        pathway_name = "ChemicalClass",
        cutoff_stat = 0.05,
        cutoff_percentage = 10,
        save_table = NULL,
        path = mp_results_dir("05_enrichment")
    ),
    error = function(e) {
        message("Chemical-class ORA skipped: ", conditionMessage(e))
        NULL
    }
)

if (!is.null(ora_chem)) head(ora_chem$ClusterGosummary)

# %%
saveRDS(list(kegg = ora_results, clustered = clustered_kegg, chemclass = ora_chem),
        file.path(mp_results_dir(), "ora_results.rds"))

# %% [markdown]
# **Recap.** Three enrichment angles on the same dma table: raw KEGG ORA,
# de-duplicated KEGG ORA via `cluster_pk()`, and chemical-class ORA. The
# next script visualises one of these as a small network.
