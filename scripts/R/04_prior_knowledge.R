# %% [markdown]
# # 4. Metabolomics prior knowledge from OmnipathR
#
# OmnipathR has gained substantial metabolomics coverage in the last year.
# The four resources we'll use:
#
# - **MetalinksDB** — metabolite ↔ protein interactions (Saez group)
# - **HMDB** — Human Metabolome Database
# - **RaMP-DB** — pathway / class / chemical-property mappings
# - **RECON3D** — genome-scale metabolic model (now with HMDB IDs from
#   the Virtual Metabolic Human export)
#
# Each is fetched on demand and cached locally.

# %%
source(file.path(here::here(), "scripts/R/_utils.R"))
library(MetaProViz)
library(OmnipathR)

# %% [markdown]
# ## MetalinksDB

# %%
# What tables does MetalinksDB expose?
metalinksdb_tables()

# %%
# The 'lr' table is the ligand-receptor edge list — small molecule on
# one side, protein receptor on the other.
ml_lr <- metalinksdb_table("lr")
dim(ml_lr)
head(ml_lr)

# %% [markdown]
# MetaProViz wraps MetalinksDB into a ready-to-enrich pathway-style table
# via `metsigdb_metalinks()`:

# %%
ml_pk <- metsigdb_metalinks()
head(ml_pk)

# %% [markdown]
# ## HMDB
#
# HMDB has dozens of fields per metabolite. List them, then pull a
# focused slice.

# %%
hmdb_metabolite_fields() |> head(20)

# %%
# Just IDs and names — fast.
hmdb_ids <- hmdb_table(
    dataset = "metabolites",
    fields = c("accession", "name", "chemical_formula", "monisotopic_molecular_weight")
)
nrow(hmdb_ids)
head(hmdb_ids)

# %% [markdown]
# ## RaMP-DB
#
# RaMP unifies pathway memberships and chemical properties from KEGG,
# Reactome, WikiPathways, HMDB, ChEBI, and LipidMaps.

# %%
ramp_tables() |> head()

# %%
# Pathway memberships in long form.
ramp_pathways <- ramp_table("source")
head(ramp_pathways)

# %% [markdown]
# ## RECON3D
#
# Useful when you want to reason about reactions, compartments, or
# enzyme-metabolite relationships rather than pathway membership.

# %%
recon_meta <- recon3d_metabolites()
head(recon_meta)

# %%
recon_reactions <- recon3d_reactions()
head(recon_reactions)

# %% [markdown]
# ## Compare PK coverage
#
# Are the same metabolites covered by all of these? Use
# `compare_pk()` to see the intersection / specificity.

# %%
pk_overlap <- compare_pk(
    data = list(
        metalinks = as.data.frame(ml_pk),
        kegg      = as.data.frame(metsigdb_kegg())
    ),
    plot_name = "Metabolite coverage: MetalinksDB vs KEGG",
    save_plot = "svg",
    print_plot = TRUE,
    path = mp_results_dir("04_prior_knowledge")
)

# %% [markdown]
# ## Connect to our dma table
#
# `checkmatch_pk_to_data()` is the diagnostic that catches dimension or
# ID-type mismatches early — it tells you how many features in the data
# have at least one PK term, and how many PK terms have at least one
# matching feature.

# %%
dma_results <- readRDS(file.path(mp_results_dir(), "dma_results.rds"))
dma_table <- dma_results[["786-M1A_vs_HK2"]]$dma

# Build a feature metadata table with HMDB IDs (script 03 showed how;
# in real use this comes from the dataset's annotation file).
feature_meta <- dma_table |>
    dplyr::select(Metabolite) |>
    equivalent_id(metadata_info = c(InputID = "Metabolite"), from = "name")

# %%
match_diag <- checkmatch_pk_to_data(
    data = feature_meta,
    input_pk = ml_pk,
    metadata_info = c(InputID = "HMDB", PriorID = "hmdb", grouping_variable = NULL)
)

names(match_diag)
match_diag$data_summary

# %%
saveRDS(ml_pk, file.path(mp_results_dir(), "metalinks_pk.rds"))

# %% [markdown]
# **Recap.** Four metabolomics-relevant OmnipathR resources, each with a
# single accessor. `compare_pk()` shows where they overlap;
# `checkmatch_pk_to_data()` is the gate before enrichment in script 05.
