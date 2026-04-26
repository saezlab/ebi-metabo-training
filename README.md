# Metabolomics training — EMBL-EBI 2026

A 3-hour hands-on training in metabolomics data analysis, taught by Christina
Schmidt and Denes Turei (Saez-Rodriguez group, Heidelberg University) at
EMBL-EBI in May 2026.

The session is split into a 45-minute introductory talk followed by ~2 hours
of hands-on work. The hands-on portion uses R first (OmnipathR + MetaProViz)
and then Python (`omnipath-client`, `omnipath-metabo`).

## What's in this repo

- `notebooks/metabo_R.ipynb` — the R notebook (IRkernel)
- `notebooks/metabo_python.ipynb` — the Python notebook
- `scripts/R/` — the R notebook's content as cell-marked scripts you can run
  section by section in any IDE
- `scripts/python/` — same idea for the Python content
- `docs/` — participant-facing setup, agenda, and glossary
- `env/` — environment definitions (`pyproject.toml` for Python, `install.R`
  for R)
- `data/` — small example data; the main toy dataset is shipped inside
  MetaProViz (`MetaProViz::intracell_raw_se`)
- `2025/` — last year's notebook, kept as historical reference
- `trainer/` — internal scripts used by trainers; participants can ignore

## Quick start

Pick the path that fits your environment in `docs/00_setup.md`. The short
version:

### Python (uv)

```bash
cd env
uv sync
uv run jupyter lab
```

### R (PPM via pak)

```bash
Rscript env/install.R
```

If your machine cannot reach the Posit Public Package Manager, fall back to
the pre-built R library tarball — see `docs/01_setup_r.md`.

## Agenda at a glance

| min     | content                                                |
|---------|--------------------------------------------------------|
| 0–45    | Introductory talk (slides, no code)                    |
| 45–50   | Hands-on setup verification                            |
| 50–105  | R: data → processing → DMA → ID translation → PK → ORA |
| 105–110 | Network visualization (`viz_graph`)                    |
| 110–115 | Stretch + switch to Python                             |
| 115–155 | Python: `omnipath-client` + `omnipath-metabo` tour     |
| 155–160 | (optional) BRENDA allosteric regulation                |
| 160–180 | Q&A                                                    |

The detailed timetable lives in `docs/04_agenda.md`.

## License

BSD 3-Clause — see `LICENSE`.

## References

- **MetaProViz** — Schmidt C, Türei D, Prymidis D, Daley M, Frezza C,
  Saez-Rodriguez J. *MetaProViz: a comprehensive R toolbox for
  metabolomics data analysis and visualisation.* bioRxiv 2025.
  doi:[10.1101/2025.08.18.670781](https://doi.org/10.1101/2025.08.18.670781)
- **OmniPath (latest)** — Türei D, Schaul J, Palacio-Escat N, Bohár B,
  Bai Y, Ceccarelli F, *et al.* *OmniPath: integrated knowledgebase
  for multi-omics analysis.* Nucleic Acids Research, 54(D1):D652–D660,
  2026. doi:[10.1093/nar/gkaf1126](https://doi.org/10.1093/nar/gkaf1126)
- **OmniPath (original)** — Türei D, Valdeolivas A, Gul L, *et al.*
  *Integrated intra- and intercellular signaling knowledge for
  multicellular omics analysis.* Mol. Syst. Biol., 17:e9923, 2021.
  doi:[10.15252/msb.20209923](https://doi.org/10.15252/msb.20209923)
- **COSMOS (original)** — Dugourd A, Kuppe C, Sciacovelli M, *et al.*
  *Causal integration of multi-omics data with prior knowledge to
  generate mechanistic hypotheses.* Mol. Syst. Biol., 17(1):e9730,
  2021. doi:[10.15252/msb.20209730](https://doi.org/10.15252/msb.20209730)
- **COSMOS (latest preprint)** — *Modeling causal signal propagation
  in multi-omic factor space with COSMOS.* bioRxiv 2024.
  doi:[10.1101/2024.07.15.603538](https://doi.org/10.1101/2024.07.15.603538)

## Acknowledgements

Materials and software developed by the
[Saez Lab](https://saezlab.org/) (Heidelberg University Hospital), the
[Frezza Lab](https://frezza.cecad-labs.uni-koeln.de/) (CECAD, University
of Cologne), the
[Korcsmaros Lab](https://www.imperial.ac.uk/people/t.korcsmaros)
(Imperial College London), and the OmniPath Team.
