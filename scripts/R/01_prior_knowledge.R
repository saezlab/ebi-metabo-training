# %% [markdown]
# # 5. Metabolomics prior knowledge from MetaProViz and OmnipathR
#
# OmnipathR has gained substantial metabolomics coverage in the last year.
# MetaProViz uses Omnipath at its backend and provides tidy metabolite-sets for
# enrichment analysis.
#
# Examples we will look at:
#
# - **MetSigDB** — a curated collection of metabolite-sets for enrichment analysis
# - **MetalinksDB** — metabolite ↔ protein interactions (Saez group)
# - **RaMP-DB** — pathway / class / chemical-property mappings; covers
#   most of the ID-translation needs that HMDB also serves
# - **RECON3D** — genome-scale metabolic model (with HMDB IDs from
#   the Virtual Metabolic Human export)
#
# Each is fetched on demand and cached locally.
#
# We deliberately do **not** demonstrate `hmdb_table()` in the live
# session — the HMDB XML dump is huge (multi-GB) and HMDB.ca enforces
# bot-blocking that returns HTTP 403 from cloud-VM IP ranges. RaMP
# already provides cross-resource ID maps for the same data, so for
# this tutorial it's a strict improvement.

# Two complementary tools:
#
# - **OmnipathR** wraps RaMP-DB and its companion mapping infrastructure;
#   `translate_ids()` is the general cross-resource translator.
# - **MetaProViz** wraps OmnipathR with a tidier, table-in / table-out API
#   tuned for metabolomics workflows: `translate_id()` (singular),
#   `equivalent_id()`, and `count_id()`, etc..

# %%
source(file.path(here::here(), "scripts/R/_utils.R"))
library(MetaProViz)
library(OmnipathR)

# %% [markdown]


# %%


# %% [markdown]
# MetaProViz wraps MetalinksDB into a ready-to-enrich pathway-style table
# via `metsigdb_metalinks()`:

# %%
ml_pk <- metsigdb_metalinks()
head(ml_pk)




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
    metadata_info = list(
        metalinks = c("metabolite"),
        kegg      = c("MetaboliteID")
    ),
    plot_name = "Metabolite coverage: MetalinksDB vs KEGG",
    save_plot = NULL,
    print_plot = FALSE,
    path = mp_results_dir("04_prior_knowledge")
)











# @Denes anything below is not checked. Here please add omnipathR related things.










# %% [markdown]
# ## MetalinksDB

# %%
# What tables does MetalinksDB expose?
metalinksdb_tables()

# %%
# The 'edges' table holds every metabolite-protein edge; each row carries
# a `type` ("lr" for ligand-receptor, etc.) and a confidence score.
ml_edges <- metalinksdb_table("edges")
dim(ml_edges)
head(ml_edges)

# %%
# Filter to ligand-receptor edges only.
ml_lr <- subset(ml_edges, type == "lr")
dim(ml_lr)

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
# **Recap.** Four metabolomics-relevant OmnipathR resources, each with a
# single accessor. `compare_pk()` shows where they overlap;
# `checkmatch_pk_to_data()` is the gate before enrichment in script 05.
