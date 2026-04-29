# %% [markdown]
# # 1. `omnipath-client` tour
#
# `omnipath-client` is a lightweight HTTP client for the new OmniPath API
# (`dev.omnipathdb.org`). The pilot build serves 26 resources, many of
# them small-molecule / metabolomics related (BindingDB, ChEBI, FooDB,
# HMDB, Lipid Maps, Reactome, SIGNOR, STITCH, SwissLipids,
# WikiPathways, …).
#
# Status: **pre-alpha**, expect rough edges and breaking changes.
# A few resources (PTFI, RaMP-DB, ChEMBL) are catalogued but their data
# is not yet loaded into the pilot build — we'll skip those examples.

# %%
from _utils import results_dir
import polars as pl
import omnipath_client as oc

# %% [markdown]
# ## The resource catalog
#
# `oc.resources()` lists every source the API knows about, along with
# the kinds of data each contributes (entities, relations,
# annotations).

# %%
catalog = oc.resources()
print(f"{len(catalog)} resources")
for r in catalog:
    cats = ", ".join(r.get("categories") or []) or "—"
    print(f"  {r['resource_id']:<18} {r['resource_name']:<32} [{cats}]")

# %% [markdown]
# ## Two helpers cover most of what you need
#
# Almost every analysis question is one of two shapes:
#
# - *"Tell me about this thing"* — **`oc.lookup()`** resolves a name or
#   accession to entity records and pivots the IDs you ask for into
#   named columns.
# - *"What's connected to this thing?"* — **`oc.related()`** returns a
#   joined relations table where both sides already carry names and
#   identifiers.
#
# These wrap the lower-level `resolve()` / `entities()` / `relations()`
# primitives — the latter are still exported for paged scans, raw
# parquet, and graph export, but you rarely need them directly.

# %% [markdown]
# ## `oc.lookup()` — resolve and enrich

# %%
oc.lookup(
    ["caffeine", "metformin", "glucose"],
    id_types=["name", "chebi", "hmdb", "kegg", "drugbank"],
)

# %% [markdown]
# `id_types` accepts friendly aliases (lowercase, snake_case) that the
# client maps to the underlying MI/OM ontology codes. Defaults to
# `("name", "chebi", "hmdb", "uniprot", "genesymbol")`. When an entity
# has several values for the same id type, the shortest is picked.

# %%
oc.lookup(
    "TP53",
    id_types=["name", "uniprot", "genesymbol", "ensembl", "entrez"],
)

# %% [markdown]
# ## `oc.related()` — joined relations in one call
#
# Pass a string (auto-resolved), a primary key, or a list of either.
# Positional argument matches **either** side of the relation;
# `subject=` / `object=` pin a direction.
# Filters: `sources`, `predicates`, `relation_categories`,
# `participant_types` (with aliases like `'protein'`,
# `'small_molecule'`).

# %% [markdown]
# ### Example 1 — Compounds in a strawberry (FooDB)

# %%
oc.related(
    subject="Strawberry",
    sources=["foodb"],
    id_types=["name", "chebi", "hmdb"],
    limit=10,
).select(
    "subject_name", "predicate", "object_name",
    "object_chebi", "object_hmdb", "sources",
)

# %% [markdown]
# ### Example 2 — Drug targets for caffeine (BindingDB)

# %%
oc.related(
    "caffeine",
    sources=["bindingdb"],
    id_types=["name", "uniprot", "genesymbol"],
).select(
    "subject_name", "predicate", "object_name",
    "object_uniprot", "object_genesymbol",
).head(10)

# %% [markdown]
# ### Example 3 — Pathway members from WikiPathways and Reactome
#
# `oc.search_terms()` finds pathway IDs by name; `oc.related()` then
# pulls the members in one call. `group_by` reorders the rows so each
# pathway's members are contiguous.

# %%
hits = oc.search_terms(["glycolysis"], limit=5)
for h in hits["results"]["glycolysis"]:
    print(f"  {h['ontology_id']:<20} {h['id']:<14} {h['name']}")

# %%
oc.related(
    object=["WP253", "R-HSA-70171"],
    sources=["wikipathways", "reactome"],
    relation_categories=["annotation"],
    id_types=["name", "uniprot", "chebi"],
    group_by="object_name",
).select(
    "subject_name", "subject_entity_type", "subject_uniprot",
    "subject_chebi", "predicate", "object_name", "sources",
).head(15)

# %% [markdown]
# ### Example 4 — Filter by participant type
#
# Friendly aliases (`'protein'`, `'small_molecule'`, …) save you from
# remembering the MI codes.

# %%
oc.related(
    "metformin",
    sources=["signor"],
    participant_types=["protein"],
    id_types=["name", "uniprot"],
).select(
    "subject_name", "predicate", "object_name", "object_uniprot",
)

# %% [markdown]
# ## Quick tour — entity catalogs (no-relation resources)
#
# Some pilot resources contribute only entities (HMDB, Lipid Maps,
# SwissLipids, ChEBI). `oc.lookup()` works there too — pass a query
# (or a slice of PKs) and ask for the IDs you need.

# %%
for src in ("hmdb", "lipidmaps", "swisslipids", "chebi"):
    df = oc.entities(sources=[src])
    print(f"  {src:<14} {df.height:>8} entities")

# %%
oc.lookup(
    ["palmitic acid", "cholesterol", "phosphatidylcholine"],
    id_types=["name", "chebi", "hmdb", "lipidmaps", "swisslipids"],
)

# %% [markdown]
# ## Cache control
#
# Responses are cached on disk by default. Two helpers manage that:
#
# - `oc.cache_clear()` removes every cached entry (incl. the OpenAPI
#   spec) — useful when the server has just been re-deployed.
# - `with oc.fresh(): …` re-downloads each request the **first** time
#   it's seen inside the block, then serves later identical requests
#   from the freshly populated cache. Useful when you want fresh data
#   for a specific analysis without nuking the whole cache.

# %%
with oc.fresh():
    df = oc.related("caffeine", sources=["bindingdb"], limit=5)
df.height

# %% [markdown]
# ## Underneath: the primitives
#
# `lookup()` and `related()` are wrappers; the four building blocks are
# still there when you need raw tables, paging, or graph export:
# `oc.resolve(['name'])`, `oc.entities(sources=[…], entity_pks=[…])`,
# `oc.relations(sources=[…], …, as_graph=False)`,
# `oc.search_terms([…])`. Plus `oc.entities_slice()` and
# `oc.relations_slice()` for paged access.

# %% [markdown]
# ## Recap
#
# - `oc.resources()` — what's in the catalog.
# - `oc.lookup(query, id_types=…)` — resolve to entity record(s) with
#   the ID columns already pivoted.
# - `oc.related(query, sources=…, id_types=…, …)` — joined relations
#   table around a query in one call. Filters: `sources`, `predicates`,
#   `relation_categories`, `participant_types`; `subject=`/`object=`
#   pin direction; `group_by=` reorders; `limit=` truncates.
# - `oc.cache_clear()` and `with oc.fresh(): …` for cache control.
#
# Script 02 uses the utils API for ID translation and orthology
# mapping.
