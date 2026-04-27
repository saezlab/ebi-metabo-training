# 01 — R setup

The two R packages we use — **OmnipathR** and **MetaProViz** — pull in a
deep Bioconductor dependency tree. Compiled from source they take 20+
minutes. We avoid that by pulling **binary** packages from
[Posit Public Package Manager (PPM)](https://packagemanager.posit.co/).

## The fast path

From the repo root:

```bash
Rscript env/install.R
```

`env/install.R` configures the right repo URLs and the
`HTTPUserAgent` header that tells PPM to serve binaries on Linux,
then runs `pak::pkg_install()`. Expected time: **3–5 min on a modern
workstation, ~15 min on the EBI training-room VMs**.

When it finishes you should be able to:

```bash
Rscript -e 'library(MetaProViz); library(OmnipathR); cat("ok\n")'
```

## System prerequisites (one apt line, sudo required)

`IRkernel` (the Jupyter R kernel) depends on `pbdZMQ`, which links
against the system library `libzmq3-dev`. PPM ships R binaries that
dynamically link to it, so it must be present at the OS level. On
Ubuntu / Debian:

```bash
sudo apt-get install -y libzmq3-dev
```

On a fresh Ubuntu 24.04 VM this is the only system package
`env/install.R` needs that isn't pre-installed. EBI organisers should
run it once on the master VM before cloning. If it's missing,
`env/install.R` finishes with a prominent warning that IRkernel didn't
install — re-run after adding the system package.

## Registering the R kernel for Jupyter

After `env/install.R` AND `cd env && uv sync` have both completed,
register the R kernel so `jupyter lab` can find it:

```bash
make register-r-kernel
```

This must run *after* the Python install, because the venv's `jupyter`
needs to be on `PATH` for `IRkernel::installspec()` to find the right
location. `make setup` chains all three steps in the correct order.

## Platform notes

### Ubuntu LTS VMs (training room)

The VMs already have R installed. If the VM's apt list is locked or the
network blocks PPM, jump to the **fallback** section below.

If `viz_heatmap()` later errors with `X11 font ... could not be loaded`,
the repo's `.Rprofile` should already prevent it. If your shell does not
honour `.Rprofile` (e.g. you started R outside the project directory),
either `cd` into the repo first or run:

```bash
sudo apt install -y libcairo2 fonts-dejavu fonts-liberation libpangocairo-1.0-0
```

That gives R a working cairo device + TTF fonts; the `.Rprofile` logic
then kicks in inside the project.

### macOS

PPM serves arm64 and x86_64 binaries. `env/install.R` works as is.

### Windows

PPM serves Windows `.zip` binaries. `env/install.R` works as is. If you
don't have Rtools installed, that's fine — we never compile from source.

## Fallback — pre-built RLIB tarball

If PPM is unreachable inside the EBI training room (apt-locked VMs and a
network policy that blocks `p3m.dev`), we can drop a pre-built library
tree into your user library and skip the install step entirely.

```bash
# Find your R user library:
LIB=$(Rscript -e 'cat(.libPaths()[1])')
mkdir -p "$LIB"

# Pull and unpack the tarball (~600 MB):
curl -fsSL https://static.omnipathdb.org/metabo2026/rlib.tar.gz \
    | tar -xz -C "$LIB"

# Verify:
Rscript -e 'library(MetaProViz); library(OmnipathR); cat("ok\n")'
```

The tarball was built on the `beauty` workstation against R ≥ 4.4.0 on
Ubuntu 22.04. It is **not** portable across major R versions — if your
local R is older / newer, use the PPM path instead.

## Manual / advanced

If you prefer pure CRAN+Bioconductor without PPM:

```r
install.packages("BiocManager")
BiocManager::install(c("OmnipathR", "MetaProViz"))  # source compile, slow
```

This is the path the 2025 notebook used; it works, but plan for ≥ 20 min.
