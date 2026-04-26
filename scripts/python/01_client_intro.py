# %% [markdown]
# # 1. `omnipath-client` tour
#
# `omnipath-client` is a lightweight HTTP client for the new OmniPath API
# (`dev.omnipathdb.org`). The pilot build serves 15 resources; many are
# small-molecule / metabolomics related, including the food-compound
# databases.
#
# Status: **pre-alpha**, expect rough edges and breaking changes.

# %%
from _utils import results_dir
import omnipath_client as oc

# %% [markdown]
# ## What endpoints are exposed?

# %%
endpoints = oc.endpoints()
list(endpoints)[:10]

# %% [markdown]
# ## Discover the parameters of one endpoint

# %%
list(oc.params("interactions"))[:15]

# %%
# `oc.values(endpoint, param)` returns a list when the parameter has an
# enumerable set of allowed values, or `None` for free-form params (e.g.
# `resources` accepts any string). Try a few:
for param in ("organisms", "directed", "resources"):
    vals = oc.values("interactions", param)
    print(f"{param:10s} -> {vals if vals is None else vals[:8]}")

# %% [markdown]
# ## Fetch interactions
#
# The new OmniPath API serves the full dataset (~2.5M rows) as one
# Parquet file; filtering happens client-side. Default return is a polars
# DataFrame.

# %%
df = oc.interactions()
print(f"{df.height} rows × {df.width} columns")
df.columns

# %%
df.head()

# %% [markdown]
# ## Filter client-side with polars

# %%
import polars as pl

df.filter(pl.col("evidence_count") >= 5).head()

# %% [markdown]
# ## Search the ontology terms

# %%
oc.search_terms(["glycolysis", "tca cycle"], limit=5)

# %% [markdown]
# **Recap.** `oc.endpoints / params / values` introspect what's available;
# `oc.interactions / entities / associations` fetch data; ontology helpers
# look up biological terms. In script 02 we'll use the utils API for ID
# translation.
