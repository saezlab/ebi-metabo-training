# %% [markdown]
# # 2. Differential metabolite analysis
#
# We compare each ccRCC cell line (786-O, 786-M1A, 786-M2A) to HK2 with
# `dma()` — MetaProViz's `D`ifferential `M`etabolite `A`nalysis routine.
# `dma()` (formerly `DMA()`) consumes a `SummarizedExperiment` and returns
# one SE per pairwise contrast plus diagnostic plots.

# %%
source(file.path(here::here(), "scripts/R/_utils.R"))
library(MetaProViz)

clean_se <- readRDS(file.path(mp_results_dir(), "intracell_clean_se.rds"))
clean_se

# %% [markdown]
# ## Run `dma()`
#
# `metadata_info` is the new snake_case parameter (was `MetadataInfo`). To
# do all-vs-HK2 in one call, we set `Numerator = NULL` and
# `Denominator = "HK2"` — every other condition becomes a contrast against
# HK2. Stats engine is limma (`pval = "lmFit"`); FDR adjustment is BH.

# %%
dma_results <- dma(
    data = clean_se,
    metadata_info = c(
        Conditions = "Conditions",
        Numerator = NULL,
        Denominator = "HK2"
    ),
    pval = "lmFit",
    padj = "fdr",
    save_plot = "svg",
    save_table = "csv",
    print_plot = FALSE,
    path = mp_results_dir("02_dma")
)

names(dma_results)

# %% [markdown]
# Each list element is a contrast. Results live as new assays on the SE
# along with a tidy results table.

# %%
contrast <- "786-M1A_vs_HK2"
res_se <- dma_results[[contrast]]$SE
res_se

# %%
SummarizedExperiment::assayNames(res_se)

# %%
# The rectangular results table also comes back ready to plot.
dma_table <- dma_results[[contrast]]$dma
head(dma_table)

# %% [markdown]
# ## Volcano plot
#
# `viz_volcano()` (was `VizVolcano()`) accepts the rectangular dma table
# and uses sensible defaults; we only label a handful of metabolites.

# %%
viz_volcano(
    plot_types = "Standard",
    data = dma_table |> tibble::column_to_rownames("Metabolite"),
    cutoff_x = 0.5,
    cutoff_y = 0.05,
    select_label = c("citrate", "succinate", "lactate", "alpha-ketoglutarate"),
    plot_name = contrast,
    subtitle = "Differential metabolites: 786-M1A vs HK2",
    save_plot = "svg",
    print_plot = TRUE,
    path = mp_results_dir("02_dma")
)

# %% [markdown]
# ## Heatmap of the top differential metabolites
#
# `viz_heatmap()` is the function where the X11 font error used to bite on
# Ubuntu LTS. The repo's `.Rprofile` forces the cairo device, so this just
# works.

# %%
top_metabolites <- dma_table |>
    dplyr::arrange(p.adj) |>
    dplyr::slice_head(n = 30) |>
    dplyr::pull(Metabolite)

viz_heatmap(
    data = clean_se[top_metabolites, ],
    metadata_info = c(color = "Conditions"),
    plot_name = "Top 30 differential metabolites",
    save_plot = "svg",
    print_plot = TRUE,
    path = mp_results_dir("02_dma")
)

# %% [markdown]
# ## Sample structure: PCA
#
# A quick PCA confirms cell-line separation along PC1.

# %%
viz_pca(
    data = clean_se,
    metadata_info = c(color = "Conditions"),
    plot_name = "PCA of cleaned intracellular metabolomics",
    save_plot = "svg",
    print_plot = TRUE,
    path = mp_results_dir("02_dma")
)

# %%
saveRDS(dma_results, file.path(mp_results_dir(), "dma_results.rds"))

# %% [markdown]
# **Recap.** `dma()` produced three contrasts (`*_vs_HK2`). Volcano +
# heatmap + PCA give us a quick read on biology before we move to
# pathway-level interpretation in scripts 03-05.
