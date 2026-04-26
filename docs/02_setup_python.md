# 02 — Python setup

We use [`uv`](https://docs.astral.sh/uv/) for Python environments. It's
fast, hermetic, and doesn't need a system-wide Python.

## Install `uv`

If you don't have it yet:

```bash
# Linux / macOS
curl -LsSf https://astral.sh/uv/install.sh | sh

# Windows (PowerShell)
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
```

## Sync the environment

From the repo root:

```bash
cd env
uv sync
```

This:

1. installs Python 3.12 if it's not present,
2. creates a `.venv/` inside `env/`,
3. installs `omnipath-client`, `omnipath-metabo`, and the supporting
   data-science stack from `pyproject.toml`.

Expected time: **1–2 min** the first time; near-instant on subsequent runs.

## Verify

```bash
cd env
uv run python -c "import omnipath_client, omnipath_metabo; print('ok')"
```

## Run the notebook

```bash
cd env
uv run jupyter lab ../notebooks/metabo_python.ipynb
```

Or, for a CLI-only run-through:

```bash
uv run jupyter nbconvert --to notebook --execute --inplace ../notebooks/metabo_python.ipynb
```

## Platform notes

### macOS

`omnipath-metabo` pulls in `pypath-omnipath`, which has a hard dependency
on `igraph` and `cairo`. If `uv sync` fails compiling igraph, install the
system libraries first:

```bash
brew install igraph cairo pkg-config
```

### Windows

We recommend WSL2. Native Windows is possible but `pypath-omnipath`'s
optional C extensions can be cranky.

### Locked-down corporate proxy

If `uv sync` hangs on resolving git deps, set `UV_HTTP_TIMEOUT=600` and
make sure your proxy allows GitHub HTTPS. The git deps are pinned in
`uv.lock` so the install is deterministic.

## Pre-alpha warning

`omnipath-client` and `omnipath-metabo` are at **0.x** versions. APIs
will change. If something breaks during the session, that's a
teaching moment — file an issue at
[github.com/saezlab](https://github.com/saezlab) and we'll triage it
live.
