# AGENTS.md — trainer- and AI-facing context

Loaded automatically by AI coding assistants (Claude Code, Cursor, …)
when working in this repository. It captures context that does not
belong in user-facing docs (`README.md`, `docs/`).

## What this repo is

Materials for the EMBL-EBI 2026 metabolomics training (3 h: 45 min talk,
~2 h hands-on). Co-presenters: Christina Schmidt (MetaProViz lead author,
Saez-Rodriguez group) and Denes Turei (OmnipathR maintainer).

The session was previously delivered in 2025 as a single Google Colab
notebook (`2025/metabo_prior_knowledge_functional_analysis.ipynb`). For
2026 we restructured it as a proper repo with paired R/Python content and
a fast environment setup, after MetaProViz went through a major
CamelCase→snake_case rename (v3.0.1, May 2025) and migrated to
SummarizedExperiment (v3.99.10, Oct 2025).

## Authoring conventions

- Scripts are the source of truth; notebooks are generated from them via
  `jupytext`. Cells are marked with `# %%` (Python) / `# ---- ... ----`
  (R) headers. To rebuild notebooks: `make notebooks` (see `Makefile`).
- API: always use the new MetaProViz snake_case names (`processing`,
  `dma`, `viz_volcano`, …). The mechanical rename map lives at
  `~/contrib/MetaProViz/function_renames` and `function_param_renames`.
- Toy dataset: `MetaProViz::intracell_raw_se`. Don't switch without
  re-validating PK coverage.
- License: BSD-3 throughout (matches MetaProViz post-Feb 2026).

## Key infrastructure decisions

- **R install path**: PPM binaries via `pak` (~3–5 min). Fallback: a
  pre-built RLIB tarball at `https://static.omnipathdb.org/metabo2026/rlib.tar.gz`
  built on the `beauty` workstation by `trainer/build_rlib.sh`.
- **Python install path**: `uv` + `pyproject.toml` pinned to git tags for
  the pre-alpha `omnipath-metabo` and `omnipath-client`.
- **X11 font fix**: handled by `.Rprofile` at the repo root forcing the
  cairo device. Also document the system-package recovery in
  `docs/01_setup_r.md`.
- **Testing host**: `beauty` workstation, `ssh -p2323 omnipath@omnipathdb.org`.
  Local laptop is not a testing target.

## Where to look for source-of-truth docs

- COSMOS PKN architecture: `~/saezverse/human/plans/cosmos-pkn-master-plan.md`
- Per-package docs: `~/saezverse/human/packages/`
- ID convention rationale (ChEBI for metabolites, UniProt for proteins):
  `~/saezverse/human/decisions/`
- MetaProViz function rename maps:
  `~/contrib/MetaProViz/function_renames`,
  `~/contrib/MetaProViz/function_param_renames`

## What NOT to do

- Don't add per-cell `install.packages()` / `BiocManager::install()` —
  install is a one-shot `env/install.R`.
- Don't write CamelCase MetaProViz calls; they are removed since v3.0.1.
- Don't run heavy installs locally; use `beauty`.
- Don't change `requires-python` away from 3.12 without checking transitive
  C-extension wheels.
