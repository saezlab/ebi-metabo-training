# %% [markdown]
# # 1. OmnipathR metabolomics resources & ID translation
#
# Over the last year OmnipathR gained native accessors for almost every
# small-molecule resource we routinely reach for in a metabolomics
# workflow: **HMDB**, **RaMP-DB**, **MetalinksDB**, **RECON3D**, the
# **Chalmers Sysbio GEMs** (incl. Human-GEM), **STITCH**, and
# Reactome's **ChEBI**-keyed pathway export. Plus a generic
# `translate_ids()` that uses any of these as a backend.
#
# This script is a buffet — every section below is independent. Pick
# the resources that match your downstream question; you don't need to
# run them all in order. The final two sections (translation +
# ambiguity) work on the ccRCC tissue-metabolomics dataset and apply
# regardless of which resource sections you skipped.

# %%
source(file.path(here::here(), "scripts/R/_utils.R"))
library(OmnipathR)

# %% [markdown]
# ## What translation backends does OmnipathR know about?
#
# `id_translation_resources()` lists every resource OmnipathR can use
# as a backend for `translate_ids()`. Some return ID-mapping tables
# directly (RaMP, HMDB, Chalmers GEM); others (UniProt's UploadLists,
# Ensembl) cover proteins / genes.

# %%
id_translation_resources()

# %% [markdown]
# ## RaMP-DB
#
# RaMP unifies pathway memberships, chemical class hierarchies, and
# cross-resource ID maps from KEGG, Reactome, WikiPathways, HMDB,
# ChEBI, and LipidMaps. One SQLite download covers everything.

# %%
ramp_tables()

# %%
# Pathway memberships in long form — one row per (analyte, pathway).
ramp_table("analytehaspathway") |> head()

# %%
# The `source` table is the RaMP ID-mapping backbone — it pairs every
# external ID with its internal `rampId`, which is what `translate_ids()`
# joins on under the hood.
ramp_table("source") |> head()

# %% [markdown]
# ## MetalinksDB
#
# Metabolite ↔ protein interactions curated by the Saez group:
# enzymes, transporters, ligand-receptor pairs, and "other" protein-
# metabolite contacts.

# %%
metalinksdb_tables()

# %%
# The `edges` table holds every metabolite-protein edge with a `type`
# tag and a confidence score. Filter by type to pull a specific layer.
ml_edges <- metalinksdb_table("edges")
dim(ml_edges)
head(ml_edges)

# %%
# Ligand-receptor edges only.
ml_lr <- subset(ml_edges, type == "lr")
dim(ml_lr)

# %% [markdown]
# ## RECON3D
#
# A genome-scale metabolic model — useful when you want reactions,
# compartments, or enzyme-metabolite relationships rather than pathway
# membership. The `extra_hmdb` flag pulls HMDB cross-IDs from the
# Virtual Metabolic Human export and joins them onto the metabolite
# table.

# %%
recon3d_metabolites() |> head()

# %%
recon3d_reactions() |> head()

# %%
recon3d_compartments()

# %% [markdown]
# ## Chalmers Sysbio GEMs (Human-GEM and friends)
#
# A family of genome-scale metabolic models maintained by the Chalmers
# Sysbio group. Same shape as RECON3D (metabolites + reactions +
# genes) but with a different curation pedigree and richer ID coverage.

# %%
chalmers_gem_metabolites() |> head()

# %%
chalmers_gem_reactions() |> head()

# %%
# Cross-IDs between Chalmers' internal "metabolicatlas" labels and
# common public IDs. Powers the `chalmers = TRUE` backend of
# `translate_ids()`.
chalmers_gem_id_mapping_table("metabolicatlas", "hmdb") |> head()

# %% [markdown]
# ## Reactome ↔ ChEBI
#
# A flat ChEBI-keyed pathway export — handy when you already have
# ChEBI IDs and want pathway memberships without going through RaMP.

# %%
reactome_chebi() |> head()

# %%
reactome_chebi_pathways() |> head()

# %% [markdown]
# ## STITCH
#
# Chemical ↔ protein interactions from STRING-DB's chemistry sister
# project. Two complementary tables: `links` (just edges + scores) and
# `actions` (mode-of-action annotations).
#
# **Note**: the full STITCH download is large — pass `score_threshold`
# / organism filters to keep it manageable. Skip in the live session
# if your VM is short on disk.

# %%
# stitch_links(threshold = 700) |> head()      # uncomment to run
# stitch_actions() |> head()

# %% [markdown]
# ## HMDB
#
# Human Metabolome Database — the canonical curated metabolite
# resource. **Note**: the HMDB XML dump is multi-GB and HMDB.ca
# returns HTTP 403 from cloud-VM IP ranges. If you're on the EBI
# training-room VM, prefer the RaMP path above (which already imports
# the HMDB content). The accessor is shown for completeness.

# %%
hmdb_metabolite_fields() |> head(20)

# %%
# `hmdb_table('metabolites')` triggers the multi-GB download — only
# run this on a workstation with a reliable network and at least
# ~10 GB free. Uncomment to actually fetch.
# hmdb_table("metabolites", fields = c("accession", "name", "kegg_id"))

# %% [markdown]
# ## Metabolite ID translation with RaMP
#
# `translate_ids()` is OmnipathR's general translator. For metabolites
# the recommended backend is **RaMP** — pass `ramp = TRUE` to force it,
# or let `entity_type = 'small_molecule'` pick it automatically.
#
# We work on the same ccRCC tissue-metabolomics dataset Christina uses
# in script 03 (Hakimi et al. 2018, 138 matched ccRCC / normal pairs)
# but stick to vanilla OmnipathR functions for the translation and the
# ambiguity counting.

# %%
data(tissue_meta, package = "MetaProViz")
head(tissue_meta)

# %%
# Wrangle: keep only entries with a real metabolite name (drop the
# "X-####" placeholders), normalise the ID separators, and explode
# multi-ID cells into one row per (metabolite, HMDB) pair.
metabolites <- tissue_meta |>
    dplyr::filter(!stringr::str_detect(Metabolite, "^X\\s*-\\s*\\d+$")) |>
    dplyr::mutate(
        HMDB = normalize_id_cell(HMDB),
        KEGG = normalize_id_cell(KEGG),
        PUBCHEM = normalize_id_cell(PUBCHEM),
    ) |>
    dplyr::filter(!is.na(HMDB)) |>
    tidyr::separate_rows(HMDB, sep = ", ") |>
    dplyr::distinct(Metabolite, HMDB)

dim(metabolites)
head(metabolites)

# %% [markdown]
# ## HMDB → KEGG via RaMP
#
# `translate_ids(d, hmdb_id = hmdb, kegg, ramp = TRUE)` reads
# "the column `hmdb_id` holds HMDB IDs; add a new `kegg` column
# resolved via RaMP." `keep_untranslated = TRUE` (the default) keeps
# rows that didn't resolve so we can quantify the loss.

# %%
hmdb2kegg <- translate_ids(
    metabolites,
    HMDB = hmdb,
    kegg,
    ramp = TRUE,
)
head(hmdb2kegg)

# %%
# How many of our metabolites got at least one KEGG ID?
hmdb2kegg |>
    dplyr::group_by(Metabolite) |>
    dplyr::summarise(any_kegg = any(!is.na(kegg))) |>
    dplyr::count(any_kegg)

# %% [markdown]
# ## HMDB → ChEBI via RaMP
#
# Same pattern, different target ID type. ChEBI is the lingua franca
# of pathway databases (Reactome, WikiPathways) so this translation
# unlocks downstream pathway enrichment.

# %%
hmdb2chebi <- translate_ids(
    metabolites,
    HMDB = hmdb,
    chebi,
    ramp = TRUE,
)
head(hmdb2chebi)

# %% [markdown]
# ## Ambiguity analysis
#
# `ambiguity()` quantifies how many-to-many a translation is — the
# core problem in metabolite ID work because chemically near-identical
# species (stereoisomers, ionisation states, salt forms) often share
# IDs.
#
# - `qualify = TRUE` adds two boolean columns:
#   `ambig_<from_col>` (does this `from` value point at multiple `to`s?)
#   and `ambig_<to_col>` (does this `to` value receive multiple `from`s?)
# - `quantify = TRUE` adds the integer counts.
# - `summary = TRUE` returns a tidy one-row summary instead.

# %%
# Per-row ambiguity flags + counts.
amb <- ambiguity(
    hmdb2kegg,
    from_col = HMDB,
    to_col = kegg,
    quantify = TRUE,
    qualify = TRUE,
)
head(amb)

# %%
# One-shot summary: how many HMDB IDs map to multiple KEGGs, and vice
# versa, across the whole table?
ambiguity(
    hmdb2kegg,
    from_col = HMDB,
    to_col = kegg,
    summary = TRUE,
)

# %%
# `translate_ids()` itself can do the same accounting in one pass —
# add `quantify_ambiguity = TRUE` / `ambiguity_summary = TRUE` and
# you get the translation **and** the diagnostics from a single call.
translate_ids(
    metabolites,
    HMDB = hmdb,
    kegg,
    ramp = TRUE,
    ambiguity_summary = TRUE,
)

# %% [markdown]
# **Recap.** OmnipathR exposes the major small-molecule resources
# behind a uniform accessor pattern (`<resource>_table()` /
# `<resource>_<entity>()`), and `translate_ids(..., ramp = TRUE)` plus
# `ambiguity()` cover the ID-translation + diagnostics use case end to
# end. In script 02 we'll see how MetaProViz wraps these into a
# tidier metabolomics-workflow API; in scripts 03–05 we use both
# layers in concert.
