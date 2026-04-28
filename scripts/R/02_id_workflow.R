# %% [markdown]
# # 2. MetaProViz Metabolite ID workflow
# This is important to improving the connection between prior knowledge and
# metabolomics features.
# Many databases that collect metabolite information, such as the Human
# Metabolome Database (HMDB), include multiple entries for the same metabolite
# with different degrees of ambiguity. This poses a difficulty when assigning
# metabolite IDs to measured data where e.g. stereoisomers are not distinguished.
# Hence, if detection is unspecific, it is crucial to assign all possible
# IDs to increase the overlap with the prior knowledge.
# MetaProViz offers methodologies to solve such conflicts to allow robust mapping
# of experimental data with prior knowledge. In detail, MetaProViz performs
# feature space quality control, offers functionalities to increase the
# metabolite ID feature space, including ID translation, ID traversion through
# a metabolite ID graph and enantiomer addition and quantifies mapping ambiguities.
# this is the workflow we will follow in the next steps.

# %%
source(file.path(here::here(), "scripts/R/_utils.R"))

library(MetaProViz)

# %% [markdown]
# ## 1. Feature space quality control
#
# Analyse the existent metabolite ID space using MetaProViz `compare_pk()`
# function to check the overlap of the different ID types and the coverage of
# the feature space and `count_id()`.

# %%

# Load cleaned feature metadata with unified ID separator
MetaboliteIDs <- readRDS(file.path(mp_results_dir(), "MetaboliteIDs_clean_idseparator.rds"))

# compare id space
ccRCC_CompareIDs <- compare_pk(data = list(Biocft = MetaboliteIDs |>
                                               dplyr::rename("Class"="SUPER_PATHWAY")),
                               name_col = "Metabolite",
                               metadata_info = list(Biocft = c("KEGG", "HMDB", "PUBCHEM")),
                               plot_name = "Overlap of ID types in ccRCC data")

# %% [markdown]
# Here we notice that 76 features have no metabolite ID assigned, yet have a
# trivial name and a metabolite class assigned. For 135 metabolites we only
# have a pubchem ID, yet no HMDB or KEGG ID. Only 43% of all features have HMDB,
# KEGG and Pubchem IDs assigned, whilst 23% only had a PubChem ID assigned.
# One explanation could be that the databases covered less structures when the
# study was published in 2016.

# %%

#count ids
# 1. HMDB:
Plot1_HMDB <- count_id(MetaboliteIDs,
                       delimiter = ", ",
                       "HMDB")

# The output is a data table that is visualized in a barplot
head(Plot1_HMDB[["Table"]])
Plot1_HMDB[["Plot_Sized"]]

# 2. KEGG:
Plot1_KEGG <- count_id(MetaboliteIDs,
                       delimiter = ", ",
                       "KEGG")

# 3. PubChem:
Plot1_PubChem <- count_id(MetaboliteIDs,
                          delimiter = ", ",
                          "PUBCHEM")


# %% [markdown]
# Now we can extract some summary statistics from the count_id() output to get a
# better overview of the ID space and how it changes with the different steps of
# the workflow. For this we use our helper functions established ain our utils.

# This table stores one row per database and category, for example:
# HMDB_Original, KEGG_cleaned, PUBCHEM_Original, etc.
#
# Column meanings:
# no_ID         = number of features with no ID in that database
# Single_ID     = number of features with exactly one ID in that database
# Multiple_IDs  = number of features with more than one ID in that database
# Total_IDs     = total number of IDs assigned in that database
#                 calculated as sum(entry_count)

# %%

id_count_df <- tibble(
    row_name      = character(),
    no_ID         = integer(),
    Single_ID     = integer(),
    Multiple_IDs  = integer(),
    Total_IDs     = integer()
)

id_count_df <- append_id_counts(id_count_df, Plot1_HMDB,    "HMDB_Original")
id_count_df <- append_id_counts(id_count_df, Plot1_KEGG,    "KEGG_Original")
id_count_df <- append_id_counts(id_count_df, Plot1_PubChem, "PUBCHEM_Original")

head(id_count_df)


# %% [markdown]
# Part of the ID QC is also to check the MetaboliteOD compatibility. This checks
# for ID mismatches of features with metabolite IDs that pointed to different
# metabolite structures.

# %%

# Note: The input df does not contain ChEBI IDs. For the compatibility check,
# ChEBI IDs are internally used as possible stepstones for ID compatibility
MetaboliteIDs_compatibility_check <- seed_id_compatibility_check(
    data = MetaboliteIDs,
    id_types = c("HMDB", "KEGG", "CHEBI", "PUBCHEM"),
    delimiter = ","
)

MetaboliteIDs_pair_compatibility <- MetaboliteIDs_compatibility_check$ID_pair_compatibility
MetaboliteIDs_data_with_compatibility <- MetaboliteIDs_compatibility_check$data_with_compatibility

# 1. Let's retrieve the fully compatible features
fully_compatible_metabolites <- MetaboliteIDs_data_with_compatibility[MetaboliteIDs_data_with_compatibility$all_seed_ids_compatible == TRUE, "Metabolite"]

# retrieve the id_pairs for these fully_compatibly features
fully_compatible_id_pair_rows <-
    MetaboliteIDs_pair_compatibility %>%
    filter(
        Metabolite %in% unlist(fully_compatible_metabolites)
    )%>%
    mutate(
        manual_correction = FALSE,
        correction_tbl = NA
    )

cat("Distinct features in fully_compatible_id_pair_rows:",
    length(unique(fully_compatible_id_pair_rows$Metabolite)),
    "(checks out)\n")

# 2. Get lost metabolites
MetaboliteIDs_pair_compatibility_filtered <- MetaboliteIDs_pair_compatibility %>%
    filter(
        (all_seed_ids_compatible == TRUE) |
            (all_seed_ids_compatible == FALSE & compatibility_path == "direct") |
            (all_seed_ids_compatible == FALSE & compatibility_path == "secondary")
    )

lost_Metabolites_after_filtering <- list(
    setdiff(
        unique(MetaboliteIDs_pair_compatibility$Metabolite),
        unique(MetaboliteIDs_pair_compatibility_filtered$Metabolite)
    )
)

cat("Distinct metabolites before compatibility filtering:",
    length(unique(MetaboliteIDs_pair_compatibility$Metabolite)),
    "\n")
cat("Distinct metabolites after compatibility filtering:",
    length(unique(MetaboliteIDs_pair_compatibility_filtered$Metabolite)),
    "\n")

# Lets explore one case: N-acetyltryptophan
Trypt <- MetaboliteIDs_data_with_compatibility%>%
    filter(Metabolite== "N-acetyltryptophan")
Trypt

# Kegg C03137 is D- and Pubchem 700653 is L form.

# 3. Get the permutation_df for the partially_compatible features
partially_compatible_metabolites <-
    MetaboliteIDs_data_with_compatibility %>%
    filter(
        all_seed_ids_compatible == FALSE
    ) %>%
    filter(
        ! Metabolite %in% unlist(lost_Metabolites_after_filtering)
    )

cat("Partially compatible metabolite names:",
    length(unique(partially_compatible_metabolites$Metabolite)),
    "\n")

# get the id_pair compatibility for those
partially_compatible_id_pair_rows <-
    MetaboliteIDs_pair_compatibility %>%
    filter(
        Metabolite %in% partially_compatible_metabolites$Metabolite
    )

partially_compatible_id_pair_rows %<>%
    filter(
        compatibility_path != "no_match"   #only keep matches
    ) %>%
    mutate(
        manual_correction = TRUE,
        correction_tbl = "keeping_only_compatible_for_partially_compatible_features"
    )

# %% [markdown]
# here we:
# removed 41 partially incompatible cases (= some IDs are connected in the network
# whilst others are not)
# completely removed 33 cases with no match between IDs (=fully incompatible)
# --> manual review required. Here we only look at one example, but ignore
# those as we do not
# have the time for a manual review in this session and will just strictly filter
# those out, potentially loosing 33 features.

# %% [markdown]

# now lets summarize them again, we completely ignore the incompatible features
combined_tables <-
    rbind(
        partially_compatible_id_pair_rows,
        fully_compatible_id_pair_rows
    )

# join back together based on "original_row_id", summarizing the IDs per type
MetaboliteIDs_cleaned <- combined_tables %>%
    group_by(original_row_id) %>%
    summarise(
        Metabolite    = first(Metabolite),
        CAS           = first(CAS),
        SUPER_PATHWAY = first(SUPER_PATHWAY),
        SUB_PATHWAY   = first(SUB_PATHWAY),
        COMP_ID       = first(COMP_ID),
        PLATFORM      = first(PLATFORM),
        RI            = first(RI),
        MASS          = first(MASS),

        PUBCHEM = {
            x <- trimws(as.character(PUBCHEM))
            x[x == ""] <- NA_character_
            x <- unique(na.omit(x))
            if (length(x) == 0) NA_character_ else paste(x, collapse = ", ")
        },

        KEGG = {
            x <- trimws(as.character(KEGG))
            x[x == ""] <- NA_character_
            x <- unique(na.omit(x))
            if (length(x) == 0) NA_character_ else paste(x, collapse = ", ")
        },

        HMDB = {
            x <- trimws(as.character(HMDB))
            x[x == ""] <- NA_character_
            x <- unique(na.omit(x))
            if (length(x) == 0) NA_character_ else paste(x, collapse = ", ")
        },

        CHEBI = {
            x <- trimws(as.character(CHEBI))
            x[x == ""] <- NA_character_
            x <- unique(na.omit(x))
            if (length(x) == 0) NA_character_ else paste(x, collapse = ", ")
        },

        manual_correction = first(manual_correction),
        correction_tbl = first(correction_tbl),

        .groups = "drop"
    ) %>%
    select(
        Metabolite,
        CAS,
        SUPER_PATHWAY,
        SUB_PATHWAY,
        COMP_ID,
        PLATFORM,
        RI,
        MASS,
        PUBCHEM,
        KEGG,
        HMDB,
        CHEBI,
        manual_correction,
        correction_tbl
    )

# lets check number of IDs and add to our summary table
ccRCC_CompareIDs_cleaned <- MetaProViz::compare_pk(data = list(Biocft = MetaboliteIDs_cleaned |> dplyr::rename("Class"="SUPER_PATHWAY")),
                                                   name_col = "Metabolite",
                                                   metadata_info = list(Biocft = c("KEGG", "HMDB", "PUBCHEM")),
                                                   plot_name = "Overlap of ID types in ccRCC data")


Plot2_HMDB <- count_id(MetaboliteIDs_cleaned,
                       delimiter = ", ",
                       "HMDB")

# 2. KEGG:
Plot2_KEGG <- count_id(MetaboliteIDs_cleaned,
                       delimiter = ", ",
                       "KEGG")

# 3. PubChem:
Plot2_PubChem <- count_id(MetaboliteIDs_cleaned,
                          delimiter = ", ",
                          "PUBCHEM")


# Add to our summary table:
# cleaned
id_count_df <- append_id_counts(id_count_df, Plot2_HMDB,    "HMDB_Cleaned")
id_count_df <- append_id_counts(id_count_df, Plot2_KEGG,    "KEGG_Cleaned")
id_count_df <- append_id_counts(id_count_df, Plot2_PubChem, "PUBCHEM_Cleaned")

## Calculate delta rows
delta_df <- calculate_id_deltas(id_count_df, "Original", "Cleaned")

# %% [markdown]
# ## 2. Translate Cas to metabolite ID
# Features with no HMDB, KEGG or PubChem ID could be translated from the CAS numbers
# as there are some cases in which we have a CAS number, yet no HMDB, PubChem
# or KEGG ID. We can use the CAS number to check if we can find a metabolite ID
# for these features.

# %%

# Extract features with No HMDB, KEGG or PubChem ID:
features_no_ids <- MetaboliteIDs_cleaned %>%
    dplyr::filter(
        (is.na(HMDB)    | trimws(HMDB) %in% c("", "NA")) &
            (is.na(KEGG)    | trimws(KEGG) %in% c("", "NA")) &
            (is.na(PUBCHEM) | trimws(PUBCHEM) %in% c("", "NA"))
    )

#Of those some may have a CAS number:
features_no_ids_with_cas <- features_no_ids %>%
    dplyr::filter(!(is.na(CAS) | trimws(CAS) %in% c("", "NA")))


print(paste0("We have ", nrow(features_no_ids_with_cas),
             " features with CAS number but no other metabolite ID and ",
             nrow(features_no_ids)- nrow(features_no_ids_with_cas),
             " features with no CAS number and no other metabolite ID."))

# translate IDs using MetaProViz
features_ids_from_cas <- translate_id(data = features_no_ids_with_cas,
                                      metadata_info = list(InputID = "CAS",
                                                           grouping_variable = "SUPER_PATHWAY"),
                                      from = "cas",
                                      to = c("hmdb", "kegg", "pubchem"))

# Keep only rows where at least one new ID was actually found
cas_ids_found <- features_ids_from_cas[["TranslatedDF"]] %>%
    dplyr::filter(
        !(is.na(hmdb)    | hmdb    == "") |
            !(is.na(kegg)    | kegg    == "") |
            !(is.na(pubchem) | pubchem == "")
    ) %>%
    # Replace the (empty) original ID columns with the translated ones
    dplyr::mutate(
        HMDB = normalize_id_cell(hmdb),
        KEGG = normalize_id_cell(kegg),
        PUBCHEM = normalize_id_cell(pubchem)
    ) %>%
    dplyr::select(-hmdb, -kegg, -pubchem)

# Merge back: update matching rows in MetaboliteIDs by COMP_ID
MetaboliteIDs_Translated <- MetaboliteIDs_cleaned %>%
    dplyr::rows_update(cas_ids_found, by = "COMP_ID")


# Now we can repeat the `count_id` and `compare_pk` plot after every change to
# the number of metabolite IDs
ccRCC_CompareIDs_Translated <- MetaProViz::compare_pk(data = list(Biocft = MetaboliteIDs_Translated |> dplyr::rename("Class"="SUPER_PATHWAY")),
                                                   name_col = "Metabolite",
                                                   metadata_info = list(Biocft = c("KEGG", "HMDB", "PUBCHEM")),
                                                   plot_name = "Overlap of ID types in ccRCC data")


Plot3_HMDB <- count_id(MetaboliteIDs_Translated,
                       delimiter = ", ",
                       "HMDB")

# 2. KEGG:
Plot3_KEGG <- count_id(MetaboliteIDs_Translated,
                       delimiter = ", ",
                       "KEGG")

# 3. PubChem:
Plot3_PubChem <- count_id(MetaboliteIDs_Translated,
                          delimiter = ", ",
                          "PUBCHEM")

# add translated to our summarized DF
id_count_df <- append_id_counts(id_count_df, Plot3_HMDB,    "HMDB_Translated")
id_count_df <- append_id_counts(id_count_df, Plot3_KEGG,    "KEGG_Translated")
id_count_df <- append_id_counts(id_count_df, Plot3_PubChem, "PUBCHEM_Translated")

## Calculate delta rows
delta_df <- rbind(
    delta_df,
    calculate_id_deltas(id_count_df, "Original", "Translated"),
    calculate_id_deltas(id_count_df, "Cleaned", "Translated")
)

# %% [markdown]
# ## 3. Traverse metabolite IDs
#  we fill the gaps by expanding the metabolite identifiers across HMDB, KEGG
# and PubChem by building and traversing a metabolite ID graph. This fills the
# gaps by iteratively going through the cross-database mappings and collecting
# all connected IDs whilst additionally adding ChEBI IDs to the features.

# %%

# Harmonize ID separators for traversal (function expects one delimiter)
Input_Traverse <- MetaboliteIDs_Translated %>%
    dplyr::mutate(
        HMDB = normalize_id_cell(HMDB),
        KEGG = normalize_id_cell(KEGG),
        PUBCHEM = normalize_id_cell(PUBCHEM)
    )

Results_Traverse <- MetaProViz::traverse_ids(
    data = Input_Traverse,
    id_types = c("HMDB", "KEGG", "CHEBI", "PUBCHEM"),
    delimiter = ",",
    path = "MetaProViz_Results/PK/Traverse"
)

## inspect results
traverse_ID_pair_compatibility <- Results_Traverse$ID_pair_compatibility
traverse_ID_edges <- Results_Traverse$ID_Edges_prior_knowledge
traverse_ID_ExpandedDF <- Results_Traverse$ExpandedDF

## how many features of the traverse_ID_ExpandedDF are all_seed_ids_compatible?
cat("Fully compatible features (PUBCHEM/KEGG/HMDB):",
    length(which(traverse_ID_ExpandedDF$all_seed_ids_compatible == TRUE)),
    "\n")

## how many features of the traverse_ID_ExpandedDF are NOT all_seed_ids_compatible?
cat("NOT fully compatible features (PUBCHEM/KEGG/HMDB):",
    length(which(traverse_ID_ExpandedDF$all_seed_ids_compatible == FALSE)),
    "\n")

## how many of these features with at least some incompatibility were NOT manually curated?
cat("NOT fully compatible features (PUBCHEM/KEGG/HMDB) WITHOUT a 'manual_curation' tag:",
    length(which(traverse_ID_ExpandedDF$all_seed_ids_compatible == FALSE &
                     traverse_ID_ExpandedDF$manual_curation == FALSE)),
    "\n")

# Incorporate the newly added features into a new df "MetaboliteIDs_traverse"

MetaboliteIDs_traverse <-
    traverse_ID_ExpandedDF %>%
    mutate(
        PUBCHEM = {
            PUBCHEM_translated %>%
                normalize_id_cell() %>%
                gsub("CID", "", .)
        },
        KEGG = KEGG_translated %>% normalize_id_cell(),
        HMDB = HMDB_translated %>% normalize_id_cell(),
        CHEBI = CHEBI_translated %>% normalize_id_cell()
    ) %>%
    select(
        - all_seed_ids_compatible,
        - row_id,
        - HMDB_translated,
        - KEGG_translated,
        - CHEBI_translated,
        - PUBCHEM_translated,
        - n_seed_ids,
        - n_HMDB_translated,
        - n_KEGG_translated,
        - n_CHEBI_translated,
        - n_PUBCHEM_translated,
        - mapping_expanded,
        - ambiguous_seed,
        - large_mapping
    )


# Now we can repeat the `count_id` and `compare_pk` plot after every change to
# the number of metabolite IDs
ccRCC_CompareIDs_Traverse <- MetaProViz::compare_pk(data = list(Biocft = MetaboliteIDs_traverse |> dplyr::rename("Class"="SUPER_PATHWAY")),
                                                      name_col = "Metabolite",
                                                      metadata_info = list(Biocft = c("KEGG", "HMDB", "PUBCHEM")),
                                                      plot_name = "Overlap of ID types in ccRCC data")


Plot4_HMDB <- count_id(MetaboliteIDs_traverse,
                       delimiter = ", ",
                       "HMDB")

# 2. KEGG:
Plot4_KEGG <- count_id(MetaboliteIDs_traverse,
                       delimiter = ", ",
                       "KEGG")

# 3. PubChem:
Plot4_PubChem <- count_id(MetaboliteIDs_traverse,
                          delimiter = ", ",
                          "PUBCHEM")

# 3. Chebi:
Plot4_CHEBI <- count_id(MetaboliteIDs_traverse,
                          delimiter = ", ",
                          "CHEBI")

# extend counting dataframe with traverse_id results
# traverse
id_count_df <- append_id_counts(id_count_df, Plot4_HMDB,    "HMDB_Traverse")
id_count_df <- append_id_counts(id_count_df, Plot4_KEGG,    "KEGG_Traverse")
id_count_df <- append_id_counts(id_count_df, Plot4_PubChem, "PUBCHEM_Traverse")
id_count_df <- append_id_counts(id_count_df, Plot4_CHEBI, "CHEBI_Traverse")

# Calculate delta rows
delta_df <- rbind(
    delta_df,
    calculate_id_deltas(id_count_df, "Original", "Traverse"),
    calculate_id_deltas(id_count_df, "Cleaned", "Traverse"),
    calculate_id_deltas(id_count_df, "Translated", "Traverse")
)

# %% [markdown]
# ## 4. Equivalent IDs
#

# %%





# %%
saveRDS(id_count_df, file.path(mp_results_dir(), "id_count_df.rds"))
saveRDS( delta_df, file.path(mp_results_dir(), "delta_df.rds"))
saveRDS(MetaboliteIDs_traverse, file.path(mp_results_dir(), "MetaboliteIDs_expanded.rds"))

# %% [markdown]
# **Recap.** MetaProViz offers a workflow to compile the ID feature space prior to
# enrichment analysis and mapping to PK.
