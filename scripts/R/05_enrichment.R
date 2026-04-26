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

# %%
ora_results <- list()

for (contrast in names(dma_results)) {
    dma_tab <- dma_results[[contrast]]$dma |>
        tibble::column_to_rownames("Metabolite")

    ora_results[[contrast]] <- standard_ora(
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
        save_table = "csv",
        path = mp_results_dir("05_enrichment")
    )
}

# %%
ora_results[["786-M1A_vs_HK2"]]$ClusterGosummary |> head()

# %% [markdown]
# ## Volcano-style PEA plot
#
# `viz_volcano(plot_types = "PEA")` plots the enrichment results next to
# the per-metabolite plot.

# %%
viz_volcano(
    plot_types = "PEA",
    data = dma_results[["786-M1A_vs_HK2"]]$dma |> tibble::column_to_rownames("Metabolite"),
    data2 = ora_results[["786-M1A_vs_HK2"]]$ClusterGosummary,
    plot_name = "786-M1A vs HK2 — KEGG ORA",
    save_plot = "svg",
    print_plot = TRUE,
    path = mp_results_dir("05_enrichment")
)

# %% [markdown]
# ## Reduce redundancy with `cluster_pk()`
#
# Many pathway resources contain near-duplicate terms. `cluster_pk()`
# clusters terms by their metabolite-set Jaccard similarity, then we
# pick a representative per cluster before ORA.

# %%
clustered_kegg <- cluster_pk(
    data = kegg_pw,
    metadata_info = c(term = "term", feature = "Metabolite"),
    cutoff_similarity = 0.5
)

names(clustered_kegg)
head(clustered_kegg$ClusteredPK)

# %% [markdown]
# Re-run ORA on the dereplicated PK and compare top hits.

# %%
ora_clustered <- standard_ora(
    data = dma_results[["786-M1A_vs_HK2"]]$dma |> tibble::column_to_rownames("Metabolite"),
    metadata_info = c(
        pvalColumn = "p.adj",
        percentageColumn = "t.val",
        PathwayTerm = "term",
        PathwayFeature = "Metabolite"
    ),
    input_pathway = clustered_kegg$ClusteredPK,
    pathway_name = "KEGG_clustered",
    cutoff_stat = 0.05,
    cutoff_percentage = 10,
    save_table = "csv",
    path = mp_results_dir("05_enrichment")
)

ora_clustered$ClusterGosummary |> head()

# %% [markdown]
# ## Chemical-class enrichment (added v2.1.4)
#
# The same ORA machinery runs against chemical classes — useful when
# pathway annotation is sparse but compound-class info is rich.

# %%
chem_pk <- metsigdb_chemicalclass()
head(chem_pk)

# %%
ora_chem <- standard_ora(
    data = dma_results[["786-M1A_vs_HK2"]]$dma |> tibble::column_to_rownames("Metabolite"),
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
    save_table = "csv",
    path = mp_results_dir("05_enrichment")
)

ora_chem$ClusterGosummary |> head()

# %%
saveRDS(ora_results, file.path(mp_results_dir(), "ora_kegg.rds"))

# %% [markdown]
# **Recap.** Three enrichment angles on the same dma table: raw KEGG ORA,
# de-duplicated KEGG ORA via `cluster_pk()`, and chemical-class ORA. The
# next script visualises one of these as a small network.
