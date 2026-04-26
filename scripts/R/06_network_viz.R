# %% [markdown]
# # 6. Network visualization with `viz_graph()`
#
# `viz_graph()` (new in MetaProViz 3.99.40) renders a node-link graph
# from a long-format edge table. We use it to draw a small ligand-receptor
# subnetwork around the metabolites that drove the top KEGG cluster from
# script 05.

# %%
source(file.path(here::here(), "scripts/R/_utils.R"))
library(MetaProViz)
library(OmnipathR)
library(dplyr)

# %% [markdown]
# ## Pick a focus set of metabolites

# %%
dma_results <- readRDS(file.path(mp_results_dir(), "dma_results.rds"))

top_metabolites <- dma_results[["786-M1A_vs_HK2"]]$dma |>
    dplyr::arrange(p.adj) |>
    dplyr::slice_head(n = 15) |>
    dplyr::pull(Metabolite)

top_metabolites

# %% [markdown]
# ## Slice MetalinksDB to those metabolites
#
# We pull metabolite ↔ receptor / transporter edges, then filter to our
# top-15 set.

# %%
ml_lr <- metalinksdb_table("lr")

ml_subset <- ml_lr |>
    dplyr::filter(metabolite_name %in% top_metabolites) |>
    dplyr::distinct(metabolite_name, gene_symbol, type)

dim(ml_subset)
head(ml_subset)

# %% [markdown]
# ## Draw the graph

# %%
viz_graph(
    data = ml_subset,
    metadata_info = c(source = "metabolite_name", target = "gene_symbol", type = "type"),
    plot_name = "Top differential metabolites — MetalinksDB neighbours",
    save_plot = "svg",
    print_plot = TRUE,
    path = mp_results_dir("06_network")
)

# %% [markdown]
# ## Optional: a COSMOS PKN teaser
#
# OmnipathR also ships builders that compose the full COSMOS prior
# knowledge network — multi-layer (transporters, receptors, allosteric,
# enzyme–metabolite, signalling, regulation). We won't run COSMOS itself,
# but here's the entry point — it's the same data the Python segment
# explores from a different angle.

# %%
# Just print the function, don't run — full PKN is heavy.
?cosmos_pkn

# %% [markdown]
# **End of R section.**
#
# Next: switch kernel to Python and continue with `notebooks/metabo_python.ipynb`.
