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
# ## 1. MetaProViz MetSigDB
# Here we will showcase some content of the Metabolite Signature database (MetSigDB),
# which is a curated collection of metabolite sets for enrichment analysis.
# It is built on top of OmnipathR and provides ready-to-use tables for pathway-style analyses.

# %%


# %% [markdown]
# ### 1.1. Pathway-metabolite sets
# MetaProViz includes KEGG, wikipathwyas, reactome

# %%

# KEGG
KEGG_Pathways <- metsigdb_kegg(exclude_metabolites = "all")# default= all

#Reactome
metsigdb_reactome()


# %% [markdown]
# ### 1.2. Pathway-gene-metabolite sets
# MetaProViz convert gene-sets to gene-metabolite sets and includes two genesets,
# Hallmarks and Gaude

# %%

# Gaude
data("gaude_pathways")

gaude_pathways <- make_gene_metab_set( #MetaproViz function
    input_pk =   gaude_pathways,
    metadata_info = c(Target = "gene"),
    pk_name = "gaude_pathways",
    save_table = NULL,
    exclude_metabolites = "all"
)$GeneMetabSet %>%
    mutate(
        gene_metab_source = "gaude_pathways",
        interaction_type = if_else(grepl("^HMDB", feature), "pathway-metabolite", "pathway-metabolic_enzyme")
    )


# Hallmark
data("hallmarks")

hallmarks_pathways <- make_gene_metab_set(
    input_pk = hallmarks,
    metadata_info = c(Target = "gene"),
    pk_name = "hallmarks",
    save_table = NULL,
    exclude_metabolites = "all"
)$GeneMetabSet %>%
    mutate(
        gene_metab_source = "hallmarks",
        interaction_type = if_else(grepl("^HMDB", feature), "pathway-metabolite", "pathway-metabolic_enzyme")
    )


# %% [markdown]
# ### 1.3. Chemical Class -metabolite sets
# Based on RaMP-2.0 calssification using CallyFire

# %%

# Chemical class
ChemicalClass <- metsigdb_chemicalclass()


# %% [markdown]
# ### 1.4. Cancer-metabolite sets
# Based on macDB content

# %%

# Cancer
Cancer <- metsigdb_macdb()



# %% [markdown]
# ### 1.5. Metabolite-receptor, -transporter, -enzyme sets from MetalinksDB
# MetaProViz wraps MetalinksDB into a ready-to-enrich pathway-style table
# via `metsigdb_metalinks()`:

# %%
ml_pk <- metsigdb_metalinks()
head(ml_pk)

ml_pk_expansion <- tibble::as_tibble(ml_pk)
unknown <- unique(ml_pk_expansion[["interaction_family"]][!ml_pk_expansion[["interaction_family"]] %in% c(
    "Other protein-metabolite",
    "Transporter-metabolite",
    "Receptor-metabolite",
    "Enzyme-metabolite"
)])
unknown <- unknown[!is.na(unknown)]

ml_pk_expansion <- list(
    metsigdb_metalinks = ml_pk_expansion,
    metsigdb_metalinks__other_protein_metabolite =
        dplyr::filter(ml_pk_expansion, interaction_family == "Other protein-metabolite"),
    metsigdb_metalinks__transporter_metabolite =
        dplyr::filter(ml_pk_expansion, interaction_family == "Transporter-metabolite"),
    metsigdb_metalinks__receptor_metabolite =
        dplyr::filter(ml_pk_expansion, interaction_family == "Receptor-metabolite"),
    metsigdb_metalinks__enzyme_metabolite =
        dplyr::filter(ml_pk_expansion, interaction_family == "Enzyme-metabolite")
)

# %% [markdown]
# ## Compare PK coverage
#
# Are the same metabolites covered by all of these? Use
# `compare_pk()` to see the intersection / specificity.

# %%
pk_comp_res <- compare_pk(data = list(Hallmarks = as.data.frame(hallmarks_pathways),
                                      Gaude = as.data.frame(gaude_pathways),
                                      MetalinksDB = as.data.frame(ml_pk))
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
