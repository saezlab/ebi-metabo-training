# `data/`

The training does not ship its own raw measurements. The toy dataset is
`MetaProViz::intracell_raw_se`, a `SummarizedExperiment` shipped inside
the MetaProViz R package. After running script `01_load_and_explore.R`,
intermediate artefacts (cleaned SE, dma results, …) appear in
`../results/` (git-ignored).

If you want to swap in your own data:

1. Build a `SummarizedExperiment` (rows = metabolites, columns = samples;
   sample metadata in `colData`, feature metadata in `rowData`).
2. Drop it in this directory as `your_dataset.rds`.
3. Adjust the first cell of `scripts/R/01_load_and_explore.R` to load it
   instead of `intracell_raw_se`.
4. Make sure `colData` has a `Conditions` column or pass your own column
   name via `metadata_info`.

For Python COSMOS examples, no input data is required — the resources
are fetched from `metabo.omnipathdb.org` on demand.
