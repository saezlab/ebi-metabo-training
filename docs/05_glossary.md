# 05 — Glossary

A short tour of the acronyms used today.

| Term | Stands for | What it means here |
|------|------------|---------------------|
| **PKN** | Prior Knowledge Network | A graph of known biology (interactions, reactions, regulation) used to guide or interpret data analysis. |
| **COSMOS** | Causal Oriented Search of Multi-Omics Space | A multi-omics mechanistic-modelling framework that integrates metabolomics, signalling, and transcriptomics on a multi-layer PKN. |
| **GEM** | Genome-scale Metabolic Model | A reconstruction of the entire metabolic network of a cell — every reaction, every metabolite, with stoichiometry and compartments. Examples: Human-GEM, Recon3D. |
| **SE** | `SummarizedExperiment` | Bioconductor's standard container: rows = features (metabolites), columns = samples, plus aligned metadata. MetaProViz uses SE as its canonical input/output since v3.99.10. |
| **DMA** | Differential Metabolite Analysis | Statistical comparison of metabolite abundances between conditions (Log2FC + p-values). MetaProViz function: `dma()`. |
| **ORA** | Over-Representation Analysis | Pathway enrichment via Fisher's exact test: "are my hits over-represented in pathway X?". MetaProViz function: `standard_ora()`. |
| **PEA** | Pathway Enrichment Analysis | Umbrella term covering ORA, GSEA, and others. |
| **MCA** | Metabolite Cluster Analysis | MetaProViz tool that groups metabolites by regulation patterns across conditions. Function: `mca_core()`, `mca_2cond()`. |
| **HMDB** | Human Metabolome Database | Comprehensive resource of human metabolites with rich annotations (structure, pathways, biofluids). |
| **ChEBI** | Chemical Entities of Biological Interest | The canonical metabolite ontology used by the OmniPath ecosystem. |
| **KEGG** | Kyoto Encyclopedia of Genes and Genomes | Pathway database with metabolic, signalling, and disease pathways. |
| **RaMP-DB** | Relational database of Metabolites and Pathways | Unified resource that maps across HMDB, KEGG, Reactome, WikiPathways, ChEBI, LipidMaps. |
| **MetalinksDB** | Metabolite-link Database | Saez-group resource of curated metabolite ↔ protein interactions (receptors, transporters, …). |
| **TCDB** | Transporter Classification Database | Hierarchical classification of membrane transporters. |
| **SLC** | Solute Carrier (family) | The largest family of human secondary-active transporters. |
| **STITCH** | Search Tool for Interactions of Chemicals | Database of chemical–protein interactions, both physical binding and indirect functional links. |
| **BRENDA** | The Comprehensive Enzyme Information System | Manually curated enzyme database; rich on kinetics and allosteric regulation. |
| **GRN** | Gene Regulatory Network | TF → target-gene relationships. We use **CollecTRI** (the meta-resource integrated into OmniPath). |
| **PPI** | Protein–Protein Interactions | Physical binding between proteins. |
| **ccRCC** | Clear-cell Renal Cell Carcinoma | The disease context of the toy dataset (`intracell_raw_se`). |
| **TIC** | Total Ion Count | LC-MS normalisation: divide each feature by the sample's total ion count. |
| **MVI** | Missing Value Imputation | Replace NAs / zeros with a reasonable estimate (here: half-minimum per feature). |
| **PPM** | Posit Public Package Manager | Hosted binary repository for CRAN and Bioconductor. We use it to make R installs ~10× faster. |
