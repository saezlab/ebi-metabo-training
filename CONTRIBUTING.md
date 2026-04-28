# Contributing

Short orientation for editing this repo.

## Where to edit what

| Want to change | Edit | Notes |
|---|---|---|
| Tutorial code or narrative | `scripts/R/*.R`, `scripts/python/*.py` | Scripts are the source of truth. |
| The R or Python notebook | Don't edit the `.ipynb` directly. Edit the script and rebuild. | See "Rebuilding notebooks" below. |
| Setup / agenda / glossary | `docs/*.md` | Participant-facing prose. Not part of the notebook. |
| Trainer-only context for AI / future contributors | `AGENTS.md` | Loaded by Claude Code, Cursor, etc. |
| R install logic | `env/install.R` | Smart-routes by distro; see header comments. |
| Python deps | `env/pyproject.toml` | Saezlab git deps pinned via `[tool.uv.sources]`. |

## Cell format inside scripts

Both `scripts/R/*.R` and `scripts/python/*.py` use the **jupytext "percent"
format**:

- `# %%` starts a code cell.
- `# %% [markdown]` starts a markdown cell. Each subsequent line starts
  with `# ` and is treated as markdown.
- Cells run in file order. Moving / inserting cells = moving / inserting
  `# %%` blocks.

Example:

```python
# %% [markdown]
# ## Fetch interactions
#
# The new OmniPath API serves the full dataset as one Parquet file.

# %%
import omnipath_client as oc
df = oc.interactions()
df.head()
```

## Rebuilding notebooks

After editing a script:

```bash
make notebooks
```

This concatenates each language's scripts and converts to `.ipynb` via
jupytext. The generated notebooks land in `notebooks/`. Output cells are
not committed — participants run the notebook live.

If you ran a notebook to test, **don't commit the executed `.ipynb`**.
Run `make notebooks` again or strip outputs with
`jupyter nbconvert --clear-output --inplace notebooks/*.ipynb`.

## Working in Jupyter (optional paired mode)

If you'd rather edit in JupyterLab directly and have the script auto-sync,
ask in an issue or ping Denes — we can enable jupytext's paired-notebook
mode (one-line config + a pre-commit hook that fails if the pair drifts).
By default we keep the workflow script-first to make diffs reviewable.

## Testing your changes locally

Before opening a PR:

```bash
make setup          # if you haven't yet — full env install
make notebooks      # rebuild notebooks from scripts
make check-r        # execute notebooks/metabo_R.ipynb top-to-bottom
make check-py       # execute notebooks/metabo_python.ipynb top-to-bottom
```

`check-r` / `check-py` are the smoke tests we use ourselves. They take a
few minutes each.

## Style notes

- **R**: 4-space indent, snake_case function and argument names
  (post-MetaProViz v3.0.1 convention). Native pipe `|>` is fine
  (we require R ≥ 4.0).
- **Python**: PEP 8, 4-space indent. Type hints welcome but not required.
- **Markdown cells**: keep narrative concise — the talk explains the *why*,
  the notebook explains the *what*.
- **No emojis** in code or comments unless somebody is asking for them.

## Committing

```bash
git checkout -b your-change
# … edit, rebuild notebooks, smoke-test …
git add scripts/ notebooks/ docs/ env/
git commit -m "concise summary"
git push -u origin your-change
gh pr create
```

For substantive changes, please run the smoke tests first. For typo /
markdown fixes, no smoke test needed.
