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

| time     | minutes | content                                                                |
|----------|---------|------------------------------------------------------------------------|
| 00:45    | 5       | Verify your setup: `library(MetaProViz)` / `import omnipath_client`    |
| **R portion**                                                                                    |
| 00:50    | 10      | **§1 Load + processing** — SE intro, `processing()` (script 01)        |
| 01:00    | 10      | **§2 Differential analysis** — `dma()`, volcano, heatmap (script 02)   |
| 01:10    | 10      | **§3 ID translation** — `translate_id()`, `equivalent_id()` (script 03)|
| 01:20    | 15      | **§4 Prior knowledge** — MetalinksDB, HMDB, RaMP, RECON3D (script 04)  |
| 01:35    | 10      | **§5 Enrichment + clustering** — `standard_ora`, `cluster_pk` (script 05)|
| 01:45    | 5       | **§6 Network viz** — `viz_graph()` (script 06)                         |
| 01:50    | 5       | Stretch + switch to Python                                             |
| **Python portion**                                                                               |
| 01:55    | 10      | **Py§1 client tour** — endpoints, fetch, polars/pandas (script 01)     |
| 02:05    | 10      | **Py§2 utils API** — ID translation + orthology (script 02)            |
| 02:15    | 10      | **Py§3 COSMOS PKN via client** — `cosmos.get_pkn()` (script 03)        |
| 02:25    | 10      | **Py§4 raw GEM reactions** — `gem_interactions()` (script 04)          |
| 02:35    | 5       | (optional) **Py§5 BRENDA allosteric** — `brenda_regulations()` (script 05)|
| 02:40    | 15      | Q&A / live debugging on the pre-alpha packages                         |

## Anything we don't get to

Sections 99 in R and 05 in Python are explicitly optional — they are
self-contained and can be skipped without breaking anything later.
