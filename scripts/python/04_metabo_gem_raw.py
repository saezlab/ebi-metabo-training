# %% [markdown]
# # 4. Raw GEM reactions via `omnipath-metabo`
#
# `omnipath-metabo` is the server-side builder behind the COSMOS PKN.
# Hitting it directly (rather than the client) lets us see resources in
# their original shape — before COSMOS simplifies them into a binary
# enzyme ↔ metabolite graph.
#
# We focus on **GEM (Genome-scale Metabolic Model) reactions** — these
# carry stoichiometry, compartment information, and reaction reversibility,
# which the COSMOS-formatted version largely flattens away.

# %%
from _utils import results_dir
from omnipath_metabo.datasets.cosmos.resources import gem_interactions

# %% [markdown]
# ## A few raw interactions
#
# `gem_interactions()` is a generator that yields one `Interaction`
# named-tuple per edge.

# %%
gem_iter = gem_interactions(gem="Human-GEM", organism=9606)
sample = [next(gem_iter) for _ in range(5)]
for rec in sample:
    print(rec)

# %% [markdown]
# Each record carries:
#
# - `source` / `target` — IDs (ChEBI for metabolites, UniProt for proteins)
# - `source_type` / `target_type` — `'small_molecule'` / `'protein'`
# - `interaction_type` — what the edge represents (e.g. `'catalyses'`,
#   `'transports'`)
# - `resource` — `'GEM:Human-GEM'` for metabolic reactions,
#   `'GEM_transporter:Human-GEM'` for transport reactions
# - `locations` — compartment(s) where the reaction occurs
# - `mor` — mode-of-regulation (sign, where applicable)
# - `attrs` — extra resource-specific fields

# %% [markdown]
# ## Collect everything into a DataFrame
#
# Be aware: this materialises tens of thousands of edges; takes a few
# seconds.

# %%
import pandas as pd

records = list(gem_interactions(gem="Human-GEM", organism=9606))
print(f"Total Human-GEM interactions: {len(records)}")

df = pd.DataFrame(
    {
        "source": [r.source for r in records],
        "target": [r.target for r in records],
        "interaction_type": [r.interaction_type for r in records],
        "resource": [r.resource for r in records],
        "locations": [r.locations for r in records],
        "mor": [r.mor for r in records],
    }
)
df.head()

# %% [markdown]
# ## Metabolic vs transport split

# %%
df["resource"].value_counts()

# %% [markdown]
# ## Compartment distribution
#
# GEM reactions are localised to a compartment (cytosol, mitochondrion,
# extracellular …). Transport reactions cross compartments.

# %%
from collections import Counter

loc_counter: Counter[str] = Counter()
for locs in df["locations"]:
    if locs:
        for loc in locs:
            loc_counter[loc] += 1

pd.Series(loc_counter).sort_values(ascending=False).head(15)

# %% [markdown]
# ## Slice: a single metabolite's neighbourhood
#
# Pick citrate (`CHEBI:30769`) and look at every reaction it touches.

# %%
citrate = "CHEBI:30769"
near_citrate = df[(df["source"] == citrate) | (df["target"] == citrate)]
print(f"{len(near_citrate)} reactions involve citrate")
near_citrate.head(10)

# %%
df.to_parquet(results_dir("04_gem") / "human_gem_interactions.parquet")

# %% [markdown]
# **Recap.** Same data the client serves under `enzyme_metabolite`, but
# with stoichiometry and compartment information intact. Useful when you
# need to reason about reaction direction, mass balance, or
# compartmentalisation rather than just connectivity.
