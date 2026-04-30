# 04 — Agenda

3-hour session. 45 min talk, ~2 h hands-on, plus stretch / Q&A buffer.

## Talk (00:00–00:45)

Slides — no code. Topics:

- Why metabolomics, why prior knowledge
- ID-translation challenges in small-molecule data
- The OmniPath ecosystem and its metabolomics layer
- COSMOS PKN: what it is, what it's for
- Today's hands-on: what to expect

## Hands-on (00:45–02:55)

| time     | minutes | content                                                                                  |
|----------|---------|------------------------------------------------------------------------------------------|
| 00:45    | 5       | Verify setup: `library(MetaProViz)` / `import omnipath_client`                           |
| **R portion**                                                                                                |
| 00:50    | 15      | **§1 OmnipathR metabolomics resources & translation** — RaMP, MetalinksDB, RECON3D, Chalmers GEM, Reactome+ChEBI; `translate_ids(..., ramp = TRUE)` + `ambiguity()` (script 01) |
| 01:05    | 15      | **§2 MetaProViz prior-knowledge sets** — MetSigDB pathway / chemical-class / cancer / gene-metabolite sets; `compare_pk()` (script 02) |
| 01:20    | 10      | **§3 MetaProViz ID workflow** — `count_id()`, `translate_id()`, `equivalent_id()` on the ccRCC tissue dataset (script 03) |
| 01:30    | 10      | **§4 Integrate features with prior knowledge** — mapping-ambiguity diagnostics before enrichment (script 04) |
| 01:40    | 10      | **§5 Enrichment + clustering** — `standard_ora()`, `cluster_pk()` (script 05)            |
| 01:50    | 5       | Stretch + switch to Python                                                               |
| **Python portion**                                                                                           |
| 01:55    | 10      | **Py§1 client tour** — `lookup()`, `related()`, the resource catalog (script 01)         |
| 02:05    | 10      | **Py§2 utils API** — ID translation + orthology (script 02)                              |
| 02:15    | 10      | **Py§3 COSMOS PKN via client** — `cosmos.get_pkn()` (script 03)                          |
| 02:25    | 10      | **Py§4 raw GEM reactions** — `omnipath_metabo` (script 04)                               |
| 02:35    | 5       | (optional) **Py§5 BRENDA allosteric** — `brenda_regulations()` (script 05)               |
| 02:40    | 15      | Q&A / live debugging on the pre-alpha packages                                           |

## Anything we don't get to

The R notebook ends with two **optional supplementary sections**
(`77_processing_data_cells`, `88_differential_analysis_cells`) covering
the SummarizedExperiment `processing()` and `dma()` flow — useful
context for when participants want the full upstream pipeline, but
not required for §3–§5. The Python `Py§5 BRENDA` section is also
optional and self-contained.
