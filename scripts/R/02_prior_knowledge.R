# %% [markdown]
# # 2. MetaProViz prior-knowledge sets
#
# MetaProViz wraps OmnipathR with a tidier, table-in / table-out API
# tuned for metabolomics workflows. On top of the raw OmnipathR
# accessors (which we tour in script 01) it ships **ready-to-enrich
# metabolite-sets** under one umbrella:
#
# - **MetSigDB** — curated metabolite-sets for enrichment analysis
#   (KEGG, Reactome, WikiPathways pathway sets, plus chemical-class
#   sets and a cancer-specific MaCDB set)
# - **Gene-metabolite sets** — Hallmarks and Gaude pathway gene sets
#   converted to gene + metabolite memberships
# - **MetalinksDB** — wrapped as enzyme / transporter / receptor /
#   other-protein-metabolite enrichment tables
#
# Each is fetched on demand and cached locally. `compare_pk()` lets us
# look at overlap between any combination of these sets.

# %%
source(file.path(here::here(), "scripts/R/_utils.R"))
library(MetaProViz)

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

# %% [markdown]
# **Recap.** MetaProViz wraps OmnipathR with a tidy, table-in / table-out
# API tuned for metabolomics workflows: it ships ready-to-enrich
# pathway-, gene-, chemical-class-, and metalinks-derived metabolite-sets
# under one umbrella, plus `compare_pk()` to inspect overlap. The
# underlying OmnipathR resources (MetalinksDB, RaMP, Chalmers GEM, …) are
# demonstrated directly in script 01.
