# %% [markdown]
# # Appendix — legacy and exploratory snippets
#
# These are sections that we trimmed from the main notebook to fit the
# 2-hour hands-on, but that remain useful as reference. None are required
# for the workflow above.

# %%
source(file.path(here::here(), "scripts/R/_utils.R"))
library(MetaProViz)
library(OmnipathR)

# %% [markdown]
# ## A. Working with the Biocrates feature table
#
# Biocrates measurements come with multiple comma-separated IDs per
# metabolite cell. The 2025 notebook spent ~16 cells exploring the
# implications. The condensed version:

# %%
data(biocrates_features)

biocrates_to_metalinks <- checkmatch_pk_to_data(
    data = biocrates_features,
    input_pk = metsigdb_metalinks(),
    metadata_info = c(InputID = "HMDB", PriorID = "hmdb", grouping_variable = NULL)
)

names(biocrates_to_metalinks)
biocrates_to_metalinks$data_summary

# %% [markdown]
# ## B. Mapping ambiguity in detail

# %%
example <- data.frame(
    metabolite = c("glucose", "fructose"),
    KEGG = c("C00031", "C00095")
)

translated <- translate_id(
    data = example,
    metadata_info = c(InputID = "KEGG"),
    from = "kegg",
    to = c("hmdb", "pubchem"),
    summary = TRUE
)

translated$MappingAmbiguity

# %% [markdown]
# ## C. RaMP source / pathway / chemprops table tour

# %%
ramp_table("analytesynonym") |> head()
ramp_table("chem_props") |> head()
ramp_table("reaction2protein") |> head()

# %% [markdown]
# ## D. Cache export
#
# After a session, you can tar up the OmnipathR cache directory so
# colleagues skip the re-download next time:

# %%
# omnipath_cache_path()  # uncomment to inspect
# Run from a shell:
# tar -I 'zstd -19' -cf omnipath_cache.tar.zst -C "$(Rscript -e 'cat(OmnipathR::omnipath_cache_path())')" .
