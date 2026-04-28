# %% [markdown]
# # 1. Load the data and explore the SummarizedExperiment
#
# We work with `intracell_raw_se`, a `SummarizedExperiment` shipped with
# MetaProViz. It contains intracellular metabolomics from a kidney-cancer
# study (Metabolomics Workbench `ST002224`): three ccRCC cell lines (786-O,
# 786-M1A, 786-M2A) and a non-cancerous proximal-tubule control (HK2), with
# pool samples used for QC.
#
# Since v3.99.10 (Oct 2025) MetaProViz uses `SummarizedExperiment` (SE) as
# its canonical container — the same object Bioconductor's omics packages
# expect. Each row is a metabolite; each column is a sample. Sample
# annotations live in `colData(se)`, feature annotations in `rowData(se)`,
# the actual measurements in `assays(se)`.

# %%
source(file.path(here::here(), "scripts/R/_utils.R"))
library(MetaProViz)
library(OmnipathR)

# %%
data(intracell_raw_se)
intracell_raw_se

# %% [markdown]
# ## What's in the SE?

# %%
SummarizedExperiment::assayNames(intracell_raw_se)
dim(intracell_raw_se)

# %%
# Sample metadata: condition, biological replicate, analytical replicate.
colData(intracell_raw_se) |> as.data.frame() |> head()

# %%
# Feature metadata: only metabolite names at this stage.
rowData(intracell_raw_se) |> as.data.frame() |> head()

# %%
# Raw peak values (rows = metabolites, columns = samples).
assay(intracell_raw_se)[1:6, 1:6]

# %% [markdown]
# ## Pre-processing
#
# `processing()` (was `PreProcessing()` before v3.0.1) takes one SE in,
# returns one SE out. By default it does:
#
# - **feature filtering** — drops metabolites detected in <80% of samples
#   per condition (`featurefilt = "Modified"`)
# - **TIC normalisation** — scales each sample by its total ion count
# - **half-minimum imputation** of missing values
# - **outlier detection** via Hotelling's T² (records outliers in
#   `colData()`)
#
# All choices are echoed to the log; QC plots are returned in the result
# list and also saved under `MetaProViz_Results/` inside the working dir.

# %%
processed <- processing(
    data = intracell_raw_se,
    metadata_info = c(
        Conditions = "Conditions",
        Biological_Replicates = "Biological_Replicates"
    ),
    featurefilt = "Modified",
    cutoff_featurefilt = 0.8,
    tic = TRUE,
    mvi = TRUE,
    save_plot = NULL,
    save_table = NULL,
    print_plot = FALSE,
    path = mp_results_dir("01_processing")
)

# %%
# `processing()` returns a named list with $SE / $DF / $Plot, each itself
# a list keyed by stage (`data_Rawdata`, `Preprocessing_output`, …).
# We want the final stage.
processed_se <- processed$SE$Preprocessing_output
processed_se

# %%
SummarizedExperiment::assayNames(processed_se)
table(processed_se$Outliers)

# %% [markdown]
# We drop pool samples (used for QC) and any flagged outliers before the
# differential analysis in script 02.

# %%
keep <- processed_se$Conditions != "Pool" & processed_se$Outliers == "no"
clean_se <- processed_se[, keep]
clean_se

# %%
saveRDS(clean_se, file.path(mp_results_dir(), "intracell_clean_se.rds"))

# %% [markdown]
# **Recap.** We loaded a SE, ran one `processing()` call, dropped pools and
# outliers, and saved the cleaned object. In script 02 we'll compute
# differential abundance with `dma()`.
