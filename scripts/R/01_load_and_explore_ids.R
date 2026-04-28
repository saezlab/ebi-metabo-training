# %% [markdown]
# # 1. Load the data, explore and data wrangling
#
# We work with publicly available metabolomic profiling on 138 matched clear cell
# renal cell carcinoma (ccRCC)/normal tissue pairsdownloaded from
# https://www.cell.com/cancer-cell/comments/S1535-6108(15)00468-7. Here we are
#interested in processing and working with the metababolite feature space and
#will only load the feature metadata for exploration.
#
# FYI: Since v3.99.10 (Oct 2025) MetaProViz also uses `SummarizedExperiment` (SE) as
# its canonical container — the same object Bioconductor's omics packages
# expect. Each row is a metabolite; each column is a sample. Sample
# annotations live in `colData(se)`, feature annotations in `rowData(se)`,
# the actual measurements in `assays(se)`. You can also load all data in se format
# using `data(tissue_norm_se)`

# %%
source(file.path(here::here(), "scripts/R/_utils.R"))
library(MetaProViz)
library(OmnipathR)

# %% [markdown]
# ## Load the data
#Check which type of metabolite IDs are available and what other information
#where provided by the authors.
# %%
data(tissue_meta)
head(tissue_meta)

# %% [markdown]
# ## Data wrangling
# It is important to inspect the separator of the metabolite ids and unify them,
# as it is common that are not unified.
# %%

# Global separator convention for all metabolite ID columns
id_separator <- ", "

# Normalize mixed separators (",", ";") to one global format
normalize_id_cell <- function(x, out_sep = id_separator) {
    ifelse(
        is.na(x),
        NA_character_,
        purrr::map_chr(stringr::str_split(x, "[;,]"), ~ {
            vals <- stringr::str_trim(.x)
            vals <- vals[vals != ""]
            if (length(vals) == 0) NA_character_ else paste(vals, collapse = out_sep)
        })
    )
}

MetaboliteIDs <- tissue_meta %>%
    dplyr::filter(!stringr::str_detect(Metabolite, "^X\\s*-\\s*\\d+$"))%>%# only keep entries with trivial names
    dplyr::mutate(
        SUPER_PATHWAY = dplyr::coalesce(SUPER_PATHWAY, "None"),
        SUB_PATHWAY   = dplyr::coalesce(SUB_PATHWAY, "None"),
        CAS = normalize_id_cell(CAS),
        HMDB = normalize_id_cell(HMDB),
        KEGG = normalize_id_cell(KEGG),
        PUBCHEM = normalize_id_cell(PUBCHEM)
    ) %>%
    mutate(across(where(is.character), ~ gsub(";", ",", .x)))

# save .rds file
saveRDS(MetaboliteIDs, file.path(mp_results_dir(), "MetaboliteIDs_clean_idseparator.rds"))

# %% [markdown]
# **Recap.** We loaded the feature metadata of the ccRCC dataset published by
# Hakimi et al. in 2018 and inspected the metabolite IDs available and ensured
# the metabolite ID separator is unified and saved the cleaned object.
