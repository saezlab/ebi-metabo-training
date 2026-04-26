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
oc.params("interactions")

# %%
oc.values("interactions", "resources")[:20]

# %% [markdown]
# ## Fetch a small slice of interactions
#
# Default return is a polars DataFrame; you can ask for pandas or pyarrow
# via the client constructor.

# %%
df = oc.interactions(
    resources=["SignaLink3", "SIGNOR"],
    organisms=[9606],
)
df.head()

# %%
print(f"{df.height} rows × {df.width} columns")
df.columns

# %% [markdown]
# ## Pandas backend
#
# Construct a client explicitly when you want a different backend.

# %%
client = oc.OmniPath(backend="pandas")
df_pd = client.interactions(resources=["SignaLink3"], organisms=[9606])
type(df_pd), df_pd.shape

# %% [markdown]
# ## Search the ontology terms

# %%
oc.search_terms(["glycolysis", "tca cycle"], limit=5)

# %% [markdown]
# **Recap.** `oc.endpoints / params / values` introspect what's available;
# `oc.interactions / entities / associations` fetch data; ontology helpers
# look up biological terms. In script 02 we'll use the utils API for ID
# translation.
