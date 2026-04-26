# %% [markdown]
# # 3. COSMOS PKN — fetched via the client
#
# **COSMOS** is a multi-omics mechanistic-modelling framework that
# combines metabolomics, signalling, and transcriptomics. Its Prior
# Knowledge Network (PKN) is a multi-layer graph stitched together from:
#
# - **transporters** — TCDB, SLC, GEM, Recon3D, MRCLinksDB
# - **receptors** — MRCLinksDB, STITCH
# - **allosteric regulation** — BRENDA, STITCH
# - **enzyme ↔ metabolite** — Human-GEM, Recon3D
# - **PPI** — OmniPath
# - **GRN** — CollecTRI
#
# We won't run COSMOS itself today, but we'll inspect the PKN and the
# GEM-derived layer because the binary network (reaction → reactant /
# product) is generally useful for any metabolic-network reasoning.

# %%
from _utils import results_dir
from omnipath_client import cosmos

# %% [markdown]
# ## What's available?

# %%
cosmos.categories()

# %%
cosmos.organisms()

# %%
cosmos.resources(organism="human")

# %% [markdown]
# ## Status of the live build

# %%
cosmos.status()

# %% [markdown]
# ## Fetch the enzyme ↔ metabolite layer
#
# This is the layer that captures "enzyme E catalyses a reaction
# producing/consuming metabolite M". The server delivers it pre-cleaned
# (canonical ChEBI / UniProt IDs, metabolic vs transport split).

# %%
em_df = cosmos.get_pkn(
    organism="human",
    categories="enzyme_metabolite",
    format="dataframe",
)
em_df.head()

# %%
print(f"{em_df.height} rows × {em_df.width} columns")
em_df.columns

# %% [markdown]
# ## A small subnetwork for visualisation

# %%
import networkx as nx
import matplotlib.pyplot as plt

# Take a small slice to keep the plot readable.
import polars as pl

slice_df = em_df.head(80).select(["source", "target", "interaction_type"])
G = nx.from_pandas_edgelist(
    slice_df.to_pandas(),
    source="source",
    target="target",
    edge_attr="interaction_type",
    create_using=nx.DiGraph,
)

fig, ax = plt.subplots(figsize=(9, 7))
pos = nx.spring_layout(G, seed=42, k=0.7)
nx.draw_networkx_nodes(G, pos, node_size=80, node_color="#88aadd", ax=ax)
nx.draw_networkx_edges(G, pos, alpha=0.4, arrows=True, arrowsize=8, ax=ax)
nx.draw_networkx_labels(G, pos, font_size=6, ax=ax)
ax.set_title("First 80 enzyme ↔ metabolite edges of the COSMOS PKN")
ax.set_axis_off()
fig.savefig(results_dir("03_cosmos") / "cosmos_em_subnet.png", dpi=150, bbox_inches="tight")
plt.show()

# %% [markdown]
# ## The other categories at a glance
#
# Each is one HTTP call away; the API is uniform.

# %%
for cat in ["transporters", "receptors", "allosteric"]:
    df = cosmos.get_pkn(organism="human", categories=cat)
    print(f"{cat:<14s}  {df.height:>6d} edges")

# %% [markdown]
# **Recap.** Three lines of Python and we have a multi-layer
# metabolism-aware network. Script 04 shows what the GEM looks like
# *before* COSMOS simplifies it.
