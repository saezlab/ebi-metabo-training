# 00 — Setup overview

The default path on Ubuntu / Debian / RHEL / macOS / Windows is three
commands from the repo root:

```bash
git clone https://github.com/saezlab/ebi-metabo-training.git
cd ebi-metabo-training
make setup
```

`make setup` chains:

1. `Rscript env/install.R` — installs OmnipathR + MetaProViz and friends from PPM binaries via `pak`. ~3–5 min on a workstation, ~15 min on the EBI training-room VMs.
2. `cd env && uv sync` — Python deps including `omnipath-client`, `omnipath-metabo`, JupyterLab. ~10 s on Ubuntu.
3. `make register-r-kernel` — registers the R kernel with the venv's Jupyter so the R notebook works.

It also works as three separate steps:

```bash
Rscript env/install.R
( cd env && uv sync )
make register-r-kernel
```

## System prerequisite (Ubuntu / Debian, one-time)

The R Jupyter kernel needs `libzmq3-dev` on the system. EBI organisers
should run this once on the master VM before cloning:

```bash
sudo apt-get install -y libzmq3-dev
```

If `env/install.R` finishes with a "WARNING: IRkernel did not install"
banner, that's the missing system package. See [`01_setup_r.md`](01_setup_r.md).

## Per-platform notes

- **EBI Ubuntu LTS VMs**: as above. The default R 4.3.3 is fine — our
  patched MetaProViz pin keeps the Polychrome dep at < 1.5.4 (the
  R-4.4-only version is excluded).
- **Your own laptop** (Linux / macOS / Windows): same `make setup`. See
  [`01_setup_r.md`](01_setup_r.md) for platform-specific install notes.
- **NixOS**: `env/install.R` redirects you to `bash trainer/install-nix.sh`.
- **Google Colab** (last-resort fallback): see [`03_setup_colab.md`](03_setup_colab.md).

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
