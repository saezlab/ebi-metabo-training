# %% [markdown]
# # 3. Metabolite identifier translation
#
# Most prior-knowledge resources speak different ID dialects (HMDB, ChEBI,
# KEGG, PubChem, LipidMaps, …). Before we can connect dma results to
# pathways, we need to translate metabolite identifiers.
#
# Two complementary tools:
#
# - **OmnipathR** wraps RaMP-DB and its companion mapping infrastructure;
#   `translate_ids()` is the general cross-resource translator.
# - **MetaProViz** wraps OmnipathR with a tidier, table-in / table-out API
#   tuned for metabolomics workflows: `translate_id()` (singular),
#   `equivalent_id()`, and `count_id()`.
#
# In 2025 we showed 16 cells of variations on this. Here we pick three
# representative ones and move the rest to `99_appendix_legacy.R`.

# %%
source(file.path(here::here(), "scripts/R/_utils.R"))
library(MetaProViz)
library(OmnipathR)

# %% [markdown]
# ## What identifier types are available?

# %%
# Resources that OmnipathR can translate between (small molecule + protein).
id_translation_resources()

# %% [markdown]
# ## Example A — translate a small KEGG pathway list to HMDB and PubChem
#
# `translate_id()` takes the input column name in `metadata_info`, plus
# `from` / `to` IDs.

# %%
kegg_pw <- metsigdb_kegg()
head(kegg_pw)

# %%
kegg_to_hmdb <- translate_id(
    data = kegg_pw,
    metadata_info = c(InputID = "MetaboliteID", grouping_variable = "term"),
    from = "kegg",
    to = c("hmdb", "pubchem")
)

names(kegg_to_hmdb)
head(kegg_to_hmdb$TranslatedDF)

# %% [markdown]
# Translation is rarely 1-to-1. The result list also reports mapping
# ambiguity, which you should always check before downstream enrichment.

# %%
kegg_to_hmdb$MappingAmbiguity |> head()

# %% [markdown]
# ## Example B — `equivalent_id()` to enrich a dataset with cross-IDs
#
# Given a table that already has one ID column (here HMDB), expand it
# with all known equivalents.

# %%
example_hmdb <- data.frame(
    MetaboliteName = c("citrate", "succinate", "lactate"),
    HMDB = c("HMDB0000094", "HMDB0000254", "HMDB0000190")
)

with_equivalents <- equivalent_id(
    data = example_hmdb,
    metadata_info = c(InputID = "HMDB"),
    from = "hmdb"
)

head(with_equivalents)

# %% [markdown]
# ## Example C — quick coverage check with `count_id()`

# %%
count_id(with_equivalents, "HMDB")$result

# %% [markdown]
# **Recap.** With three concise calls we have the IDs we need to talk to
# the prior-knowledge resources in script 04. For more variations
# (Biocrates feature tables, multi-comma-separated cells, mapping
# ambiguity surgery) see `99_appendix_legacy.R`.
