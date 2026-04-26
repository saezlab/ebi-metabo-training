# 03 — Colab fallback

If neither your local machine nor the VM works, the entire session can
run in Google Colab. This is the path we used end-to-end in the 2025
training.

## Open the notebooks

Upload `notebooks/metabo_R.ipynb` and `notebooks/metabo_python.ipynb` to
your Drive, open each in Colab. For the R notebook, switch the runtime to
**R** under `Runtime → Change runtime type`.

## R install cell

Paste this as the first cell of the R notebook (above any other code):

```r
options(
    repos = c(
        CRAN = "https://p3m.dev/cran/__linux__/jammy/latest",
        BioC = "https://packagemanager.posit.co/bioconductor"
    ),
    HTTPUserAgent = sprintf(
        "R/%s R (%s)", getRversion(),
        paste(getRversion(), R.version$platform, R.version$arch, R.version$os)
    ),
    Ncpus = 2,
    bitmapType = "cairo"
)

if (!requireNamespace("pak", quietly = TRUE)) install.packages("pak")
pak::pkg_install(c("saezlab/OmnipathR", "saezlab/MetaProViz"), upgrade = FALSE, ask = FALSE)
```

Expect this cell to take ~5 min on a fresh Colab runtime — much faster
than the 20+ min source compile that would happen otherwise.

## Python install cell

Paste this as the first cell of the Python notebook:

```python
%pip install --quiet \
    "omnipath-client[pandas,polars] @ git+https://github.com/saezlab/omnipath-client@main" \
    "omnipath-metabo @ git+https://github.com/saezlab/omnipath-metabo@main" \
    polars matplotlib networkx
```

## Caveats

- Colab runtimes are ephemeral; you'll re-install if the runtime restarts.
- The free tier has limited RAM and disk; the GEM-collection cell in
  `04_metabo_gem_raw.py` may take longer.
- File-saving paths (`results/`, etc.) work but only persist for the
  session; download key outputs at the end.
- If you're using Colab as the primary path, the rest of the docs still
  apply — the agenda and glossary are independent of the runtime choice.
