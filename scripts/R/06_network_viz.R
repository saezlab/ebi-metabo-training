# %% [markdown]
# # 6. Network visualization with `viz_graph()`
#
# `viz_graph()` is MetaProViz's term-cluster network viewer, designed to
# work directly with the output of `cluster_pk()`. It expects a similarity
# matrix of pathway terms plus a cluster assignment — exactly what
# `cluster_pk()` produced in script 05.

# %%
source(file.path(here::here(), "scripts/R/_utils.R"))
library(MetaProViz)
library(OmnipathR)

# %%
ora_bundle <- readRDS(file.path(mp_results_dir(), "ora_results.rds"))
clustered_kegg <- ora_bundle$clustered
names(clustered_kegg)

# %% [markdown]
# `cluster_pk()` already builds the term-similarity network internally
# and stores the rendered ggraph in `$graph_plot`. We can either show it
# directly or re-call `viz_graph()` on the underlying `similarity_matrix`
# and `clusters` to retune visual parameters.

# %%
cat("similarity matrix dim:", dim(clustered_kegg$similarity_matrix), "\n")
cat("clusters: ", length(clustered_kegg$clusters), "term assignments\n")

# %%
# Reuse the cluster_pk-built plot.
clustered_kegg$graph_plot

# %% [markdown]
# Or re-render with a custom threshold:

# %%
viz_graph(
    similarity_matrix = clustered_kegg$similarity_matrix,
    clusters = clustered_kegg$clusters,
    plot_threshold = 0.3,
    plot_name = "KEGG pathway clusters (threshold=0.3)",
    save_plot = NULL,
    print_plot = FALSE,
    path = mp_results_dir("06_network")
)

# %% [markdown]
# ## Optional: a COSMOS PKN teaser
#
# OmnipathR also ships builders that compose the full COSMOS prior
# knowledge network — multi-layer (transporters, receptors, allosteric,
# enzyme–metabolite, signalling, regulation). We won't run COSMOS itself,
# but the entry point is `cosmos_pkn()` in OmnipathR. The same data
# surfaces in the Python segment via the `omnipath-client` library.

# %% [markdown]
# **End of R section.**
#
# Next: switch kernel to Python and continue with `notebooks/metabo_python.ipynb`.
