# %% [markdown]
# # 2. ID translation & orthology — the utils API
#
# `omnipath_client.utils` is a thin wrapper around the
# `utils.omnipathdb.org` web service. It serves the same translation /
# taxonomy / orthology logic that the legacy R `OmnipathR::translate_ids()`
# wraps locally — but as an HTTP service, so you don't need to download
# the resource files.
#
# This is the Python parallel of the R `03_id_translation.R` section.

# %%
from _utils import results_dir
from omnipath_client import utils

# %% [markdown]
# ## Available ID types

# %%
utils.id_types("uniprot")[:10]

# %% [markdown]
# ## Translate one identifier

# %%
utils.map_name("TP53", "genesymbol", "uniprot")

# %% [markdown]
# ## Translate many at once
#
# `map_names()` returns the union; `translate_column()` keeps the
# row-to-row mapping as a DataFrame.

# %%
ids = ["TP53", "MYC", "CDK2", "BRCA1"]
utils.map_names(ids, "genesymbol", "uniprot")

# %%
df = utils.translation_df(ids, "genesymbol", "uniprot")
df

# %% [markdown]
# ## Metabolite ID translation
#
# The same mechanism handles small-molecule IDs.

# %%
utils.map_name("HMDB0000094", "hmdb", "chebi")  # citrate

# %%
metabolites = ["HMDB0000094", "HMDB0000254", "HMDB0000190"]  # citrate, succinate, lactate
utils.translation_df(metabolites, "hmdb", "chebi")

# %% [markdown]
# ## Taxonomy resolution
#
# Names, IDs, codes — `resolve_organism` handles them all.

# %%
utils.ensure_ncbi_tax_id("human"), utils.ensure_ncbi_tax_id("Mus musculus"), utils.ensure_ncbi_tax_id(10090)

# %% [markdown]
# ## Orthology
#
# Translate a list of human gene symbols to mouse.

# %%
from omnipath_client.utils._orthology import orthology_df

orthology_df(
    source=9606,
    target=10090,
    id_type="genesymbol",
    identifiers=["TP53", "MYC", "CDK2"],
)

# %% [markdown]
# **Recap.** ID translation, taxonomy resolution, and orthology — all via
# a small handful of utility calls. This is the bridge that lets us
# combine human-only resources with multi-organism analyses, which we'll
# use when fetching COSMOS PKN data in script 03.
