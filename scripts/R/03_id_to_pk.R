# %% [markdown]
# # 3. Integrate feature IDs with prior knowledge and analyse mapping ambiguities
# between our feature ID space and the prior-knowledge resource of choice
#
# Most prior-knowledge resources speak different ID dialects (HMDB, ChEBI,
# KEGG, PubChem, LipidMaps, …). Before we can connect our differential analysis
# results to pathways, we need to check for mapping issues that potentially need
# to be solved.
#
# %%
source(file.path(here::here(), "scripts/R/_utils.R"))

library(MetaProViz)

# %% [markdown]
# ## 1. Load data and prior knowledge.

# We will look at different prior knowledge resources in the next section, but
# for now we will load the cleaned feature metadata object we created and KEGG
#pathways as prior knowledge
# %%

# Load our feature metadata:
MetaboliteIDs_expanded <- readRDS(file.path(mp_results_dir(), "MetaboliteIDs_expanded.rds"))

Tissue_MetaData_Extended <- MetaboliteIDs_expanded%>%
    as.data.frame(
        MetaboliteIDs_addEquivalent
    ) %>%
    select(
        Metabolite,
        KEGG,
        manual_correction,
        correction_tbl
    )

# Load KEGG pathways from MetaProViz
KEGG_Pathways <- metsigdb_kegg()

# %% [markdown]
# ## 2. Analyse mapping ambiguities between our feature ID space and the
# prior-knowledge resource of choice
# %%

#check mapping with metadata using MetaProViz
ccRCC_to_KEGGPathways <- checkmatch_pk_to_data(data = Tissue_MetaData_Extended,
                                               input_pk = KEGG_Pathways,
                                               metadata_info = c(InputID = "KEGG",
                                                                 PriorID = "MetaboliteID",
                                                                 grouping_variable = "term"))


# inspect results
ccRCC_to_KEGGPathways_data_summary <- as.data.frame(ccRCC_to_KEGGPathways$data_summary)
ccRCC_to_KEGGPathways_GroupingVariable_summary <- as.data.frame(ccRCC_to_KEGGPathways$GroupingVariable_summary)

# Add to our input
ccRCC_to_KEGGPathways_data_summary <-
    Tissue_MetaData_Extended %>%
    select(
        Metabolite,
        KEGG,
        manual_correction,
        correction_tbl
    ) %>%
    left_join(
        ccRCC_to_KEGGPathways_data_summary,
        by = "KEGG"
    )

# convert lists inside ccRCC_to_KEGGPathways_data_summary to strings
ccRCC_to_KEGGPathways_data_summary[] <- lapply(
    ccRCC_to_KEGGPathways_data_summary,
    function(x) {
        if (is.list(x)) sapply(x, toString) else x
    }
)


#Lets look at the problematic terms:
problems_terms <- ccRCC_to_KEGGPathways_GroupingVariable_summary %>%
    filter(!Group_Conflict_Notes== "None")

print(problems_terms[,c("KEGG", "original_count", "matches_count", "MetaboliteID", "term")])

# %% [markdown]
# Dependent on the biological question and the organism and prior knowledge,
# one can either maintain the metabolite ID of the more likely metabolite
# (e.g. in human its more likely that we have L-aminoacid than D-aminoacid) or
# the metabolite ID that is represented in more/less pathways (specificity).
# If we are looking into the cases where we do have multiple IDs, for cases with
# no match to the prior knowledge we can just maintain one ID, whilst for cases
# with exactly one match we should maintain the ID that is found in the prior knowledge.

# In case of `ActionRequired=="Check"`, we can look into the column `Action_Specific`
# which contains additional information. In case of the entry `KeepEachID`,
# multiple matches to the prior knowledge were found, yet the features are in
# different pathways (=GroupingVariable). Yet, in case of `KeepOneID`,
# the different IDs map to the same pathway in the prior knowledge for at least
# one case and therefore keeping both would inflate the enrichment analysis.

# %%

SelectedIDs <- ccRCC_to_KEGGPathways_data_summary %>%
    #Expand rows where Action == KeepEachID by splitting `matches`
    mutate(matches_split = if_else(Action_Specific == "KeepEachID", matches, NA_character_)) %>%
    # separate_rows(matches_split, sep = ",\\s*") %>%
    mutate(
        InputID_select = if_else(
            Action_Specific  == "KeepEachID",
            matches_split,
            InputID_select
        )
    ) %>%
    select(-matches_split) %>%
    mutate(  # remember IDs before to compare at the end of this pipe chain
        InputID_before = InputID_select
    ) %>%
    #Select one ID for AcionSpecific==KeepOneID
    dplyr::mutate(
        InputID_select = case_when(
            Action_Specific == "KeepOneID" & matches ==  "C00025, C00217, C00302" ~ "C00025", # L-Glutamate vs D-Glutamate vs Glutamate compounds. Keep L-Glutamate, most prevalent in KEGG pathways
            Action_Specific == "KeepOneID" & matches ==  "C00065, C00716, C00740" ~ "C00065", # L-Serine vs Serine vs D-Serine
            Action_Specific == "KeepOneID" & matches ==  "C00072, C01041"         ~ "C00072", # Ascorbate vs Monodehydroascorbate. almost same molecule, just one H molecule more in Ascorbate. Keep C00072 since in more pathways
            Action_Specific == "KeepOneID" & matches ==  "C00077, C00515"         ~ "C00077", # L-Ornithine vs D-Ornithine. Keep L-Ornithine
            Action_Specific == "KeepOneID" & matches ==  "C00092, C00668"         ~ "C00092, C00668", # D-Glucose 6-phosphate vs alpha-D-Glucose 6-phosphate. Both present in lots of KEGG_Pathways, with a very low intersection of pathway terms between them. 2 shared pathways and 16 non-shared ones. Remove one of the KEGG IDs from pathways which include both
            Action_Specific == "KeepOneID" & matches ==  "C00221, C00031, C00267" ~ "C00031", # These are D- and L-Glucose and alpha-D-Glucose. We have human samples, so in this conflict we will maintain L-Glucose
            Action_Specific == "KeepOneID" & matches ==  "C00258, C01921"         ~ "C00258", # D-Glycerate vs Glycocholate. This is an ID mismatch, since they are clearly very different molecules. C01921 was added at some translation step, discard it
            Action_Specific == "KeepOneID" & matches ==  "C00309, C00508"         ~ "C00309", # D-Ribulose vs L-Ribulose. Keep C00309, since both map to the same two pathways, so it is irrelevant
            Action_Specific == "KeepOneID" & matches ==  "C00379, C01904"         ~ "C00379", # Xylitol vs D-Arabitol/D-Lyxitol. Stereochemic difference only.  C00379 maps to one more pathway
            Action_Specific == "KeepOneID" & matches ==  "C00474, C00532, C01904" ~ "C00474", # Ribitol/Adonitol vs L-Arabitol vs D-Arabitol. C00474 maps to one more pathway
            Action_Specific == "KeepOneID" & matches ==  "C00502, C05411"         ~ "C05411", # D-Xylonate vs L-Xylonate. Both map to two pathways, one overlapping. We keep L
            Action_Specific == "KeepOneID" & matches ==  "C01087, C02630"         ~ "C01087, C02630", # (R)-2-Hydroxyglutarate vs 2-Hydroxyglutarate. Both map to three pathways, one overlapping. --> Remove (R)-2-Hydroxyglutarate from KEGG pathway "Metabolic Pathways"
            Action_Specific == "KeepOneID" & matches ==  "C03242, C16522"         ~ "C03242", # Dihomo-gamma-linolenate vs Icosatrienoic acid. Both fatty acids with different double bonds. C03242 maps to two more pathways.
            Action_Specific == "KeepOneID" & matches ==  "C03460, C03722"         ~ "C03722", # 2-Methylprop-2-enoyl-CoA versus Quinolinate. No evidence, hence we keep the one present in more pathways (C03722=7 pathways, C03460=2 pathway)
            Action_Specific == "KeepOneID" & matches ==  "C05793, C05794"         ~ "C05793", # L-Urobilin vs Urobilin. C05793 was in originally assigned, keep it.
            Action_Specific == "KeepOneID" & matches ==  "C17737, C00695"         ~ "C00695", # Allocholic acid versus Cholic acid. No evidence, hence we keep the one present in more pathways (C00695 = 4 pathways, C17737 = 1 pathway)
            Action_Specific == "KeepOneID" ~ InputID_select,  # Keep NA where not matched manually
            TRUE ~ InputID_select
        ),
        corrected_during_checkmatch = is.na(InputID_before) ## flag whether changed above
    ) %>%
    select(  ## remove temp column
        -InputID_before
    )

# %% [markdown]
# We identified that in some cases in our data, there are two MetaboliteIDs with e.g.
# stereochemical differences but they map to multiple pathways. Therefore, we are
# going to remember them here and later remove them from the Pathway PK
#
# Remove (R)-2-Hydroxyglutarate (C01087) from KEGG pathway "Metabolic Pathways"
# C00092, C00668: remove C00668 from Pathways which contain both of them
# %%


# %% [markdown]
# Lastly, we need to add the column including our selected IDs to the metadata table.
# %%

Tissue_MetaData_Extended_cleaned <-
    merge(
        x = SelectedIDs %>%
            select(Metabolite, InputID_select, corrected_during_checkmatch),
        y = Tissue_MetaData_Extended,
        by = "Metabolite",
        all.y = TRUE
    ) %>%
    select(
        Metabolite, KEGG, InputID_select, manual_correction, correction_tbl, corrected_during_checkmatch
    )


saveRDS(Tissue_MetaData_Extended_cleaned, file.path(mp_results_dir(), "MetaboliteIDs_expanded_cleanedKEGG.rds"))

# %% [markdown]
# ## 3. Enrichment Analysis
# %%




# %% [markdown]
# `cluster_pk()` already builds the term-similarity network internally
# and stores the rendered ggraph in `$graph_plot`. We can either show it
# directly or re-call `viz_graph()` on the underlying `similarity_matrix`
# and `clusters` to retune visual parameters.

# %%



# %% [markdown]
# **Recap.** We created final table that will be used as input for the
# enrichment analysis using KEGG as prior knowledge
