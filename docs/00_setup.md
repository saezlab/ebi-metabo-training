# 00 — Setup overview

Pick the path that matches your environment. The hands-on works on:

- **Ubuntu LTS VM** provided by EBI (training-room machines). Follow
  [`01_setup_r.md`](01_setup_r.md) and [`02_setup_python.md`](02_setup_python.md).
- **Your own laptop** (Linux / macOS / Windows). Same files; pay attention
  to the platform-specific notes near the bottom of each.
- **Google Colab** (last-resort fallback). Follow [`03_setup_colab.md`](03_setup_colab.md).

## Two environments

The training has separate R and Python halves; install both before the
session starts.

| Half | Tool         | One-liner                                  |
|------|--------------|--------------------------------------------|
| R    | `pak` + PPM  | `Rscript env/install.R`                    |
| Py   | `uv`         | `cd env && uv sync`                        |

If R install is stuck on a "compiling from source" message, you are not
getting binaries. Stop and read [`01_setup_r.md`](01_setup_r.md) — the
likely fix is one missing config line, the fallback is a pre-built RLIB
tarball.

## Verifying

A working install means these run silently:

```bash
Rscript -e 'library(MetaProViz); library(OmnipathR); data(intracell_raw_se); cat("ok\n")'
cd env && uv run python -c "import omnipath_client, omnipath_metabo; print('ok')"
```

If both print `ok`, you're set. Open `notebooks/metabo_R.ipynb` to begin.

## Where stuff lives once installed

| What            | Where                                                    |
|-----------------|----------------------------------------------------------|
| R packages      | `~/R/x86_64-pc-linux-gnu-library/<r-version>/` (Linux)   |
| Python venv     | `env/.venv/`                                             |
| OmnipathR cache | `~/.cache/OmnipathR/` or platform equivalent             |
| Notebooks       | `notebooks/`                                             |
| Results         | `results/` — git-ignored, safe to wipe                   |

## Need help

If something breaks at the start of the session, raise your hand. If
something breaks before the session, open an issue on
[github.com/saezlab/ebi-metabo-training](https://github.com/saezlab/ebi-metabo-training).
