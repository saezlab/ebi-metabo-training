# %% [markdown]
# # 5. (OPTIONAL) BRENDA allosteric regulation
#
# **Skip if running short on time.** This section showcases a single
# resource — BRENDA — whose depth and curation quality make it worth a
# brief stop.
#
# BRENDA catalogues enzyme function with manual literature curation: each
# regulator is annotated with the reference(s) and, often, with the
# specific kinetic effect. For metabolomics modelling, this is one of the
# few places you can find systematic small-molecule → enzyme allosteric
# regulation data.

# %%
from _utils import results_dir
from omnipath_metabo.datasets.cosmos.resources import brenda_regulations

# %% [markdown]
# ## A few raw regulations

# %%
sample = []
gen = brenda_regulations(organism=9606)
for _ in range(5):
    sample.append(next(gen))

for rec in sample:
    print(rec)

# %% [markdown]
# ## Collect everything

# %%
import pandas as pd

records = list(brenda_regulations(organism=9606))
print(f"Total human BRENDA allosteric regulations: {len(records)}")

df = pd.DataFrame(
    {
        "regulator": [r.source for r in records],
        "enzyme": [r.target for r in records],
        "interaction_type": [r.interaction_type for r in records],
        "mor": [r.mor for r in records],
        "resource": [r.resource for r in records],
    }
)
df.head()

# %% [markdown]
# ## Mode of regulation distribution
#
# `mor` (mode-of-regulation) carries the sign: activation, inhibition, or
# unknown.

# %%
df["mor"].value_counts(dropna=False)

# %% [markdown]
# ## Most-regulated enzymes

# %%
df.groupby("enzyme").size().sort_values(ascending=False).head(15)

# %% [markdown]
# ## Most "active" regulators

# %%
df.groupby("regulator").size().sort_values(ascending=False).head(15)

# %%
df.to_parquet(results_dir("05_brenda") / "brenda_allosteric.parquet")

# %% [markdown]
# **Wrap up.**
#
# Today we walked from raw metabolomics measurements through differential
# analysis, ID translation, prior-knowledge access, enrichment, and into
# multi-layer mechanistic networks. Two takeaways:
#
# 1. The R side (OmnipathR + MetaProViz) is now a coherent SE-centric
#    pipeline; the API is stable, vignettes are up to date, and a
#    Bioconductor release lands shortly.
# 2. The Python side (omnipath-client + omnipath-metabo) is fresh and
#    pre-alpha. Bug reports welcome at
#    [github.com/saezlab](https://github.com/saezlab).
