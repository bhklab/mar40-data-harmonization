#------------------------------------------------------------------
# MAR-40 | Cross-Site Clinical Cohort Characterization and Visualization
# Version: 1.1
#------------------------------------------------------------------
# PURPOSE
#   Generate reproducible cohort-level descriptive summaries,
#   visualizations, and metadata availability reports from
#   standardized MAR-40 clinical and molecular metadata.
#
# COLLABORATING INSTITUTIONS
#   University Health Network (UHN)
#   University College London (UCL)
#   McGill University
#
# RELATED DOCUMENTATION
#   docs/data_curation_SOP.md
#   docs/data_dictionary.md
#   docs/quality_control.md
#   docs/data_sources.md
#   docs/usage.md
#
# INPUT REQUIREMENTS
#   A harmonized sample-level CSV with:
#     cohort, patientid, sampleid
#
#   Additional clinical and molecular metadata are optional.
#   Fully or partially missing variables are permitted.
#
# IMPORTANT SCIENTIFIC CONVENTIONS
#   Sex: F, M, NA
#   Response: R, NR, NA
#   RECIST: CR, PR, SD, PD, NE, NA
#   Missing values must never be interpreted as negative results.
#   Survival times must already be standardized upstream.
#
# ANALYSIS UNITS
#   Cancer and treatment donuts: samples
#   Sex and RECIST: unique cohort-patients
#   Sampling timepoints: samples
#   Availability heatmap: cohort-level presence/absence
#
# NOTE
#   This script is descriptive. It does not conduct survival
#   analysis, biomarker discovery, molecular reprocessing,
#   or source-specific clinical curation.
#
# EXECUTION FROM REPOSITORY ROOT
#   Rscript scripts/MAR40_cohort_visualization.R
#
#   Optional custom paths:
#   Rscript scripts/MAR40_cohort_visualization.R INPUT.csv OUTPUT_DIR
#
#------------------------------------------------------------------
#------------------------------------------------------------------
# STEP 1. CHECK PACKAGES AND DEFINE PROJECT PATHS
#------------------------------------------------------------------

required_packages <- c(
  "ggplot2",
  "dplyr",
  "tidyr",
  "paletteer",
  "ComplexHeatmap"
)

missing_packages <- required_packages[
  !vapply(
    required_packages,
    requireNamespace,
    logical(1),
    quietly = TRUE
  )
]

if (length(missing_packages) > 0) {
  stop(
    "Missing required R packages: ",
    paste(missing_packages, collapse = ", "),
    "\nInstall the packages in the approved project environment.",
    call. = FALSE
  )
}

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(tidyr)
  library(ComplexHeatmap)
})

#--------------------------------------------------------------
# 1.1. Configure input and output paths
#--------------------------------------------------------------
args <- commandArgs(trailingOnly = TRUE)

if (length(args) > 2L) {
  stop(
    "Usage: Rscript scripts/MAR40_cohort_visualization.R ",
    "[INPUT.csv] [OUTPUT_DIR]",
    call. = FALSE
  )
}

default_input <- file.path(
  "data",
  "examples",
  "MAR40_synthetic_sample_level.csv"
)

default_output <- file.path(
  "data",
  "results",
  "figures"
)

input_file <- if (length(args) >= 1L) {
  args[[1]]
} else {
  default_input
}

outdir <- if (length(args) >= 2L) {
  args[[2]]
} else {
  default_output
}

if (!file.exists(input_file)) {
  stop(
    "Input file not found: ", input_file,
    "\nPlease provide a standardized MAR-40 sample-level CSV.",
    "\nDefault example location: ", default_input,
    call. = FALSE
  )
}

dir.create(
  outdir,
  recursive = TRUE,
  showWarnings = FALSE
)

if (!dir.exists(outdir)) {
  stop("Unable to create output directory: ", outdir)
}

message("Input: ", normalizePath(input_file))
message("Output: ", normalizePath(outdir))

#------------------------------------------------------------------
# STEP 2. DEFINE FIXED COLOR PALETTES
#------------------------------------------------------------------
# These colors are fixed across sites and runs.
# Unexpected category values must be reviewed rather than
# silently assigned new colors.
#------------------------------------------------------------------

missing_color <- "#D4D4D4"

#--------------------------------------------------------------
# 2.1. Cancer types
#--------------------------------------------------------------

col_cancer <- c(
  "Melanoma"      = "#E76254",
  "Lung"          = "#376795",
  "Kidney"        = "#4EA699",
  "Bladder"       = "#D9AE2C",
  "Brain"         = "#8491BE",
  "Ureteral"      = "#A06177",
  "Head and neck" = "#EF8A47",
  "Breast"        = "#68855C",
  "Prostate"      = "#625377",
  "Colorectal"    = "#59B992",
  "Other"         = "#8C785D",
  "Missing"       = missing_color
)

#--------------------------------------------------------------
# 2.2. Immunotherapy treatment categories
#--------------------------------------------------------------

col_treatment <- c(
  "PD-(L)1"  = "#6B8CB2",
  "CTLA4"    = "#B7AC69",
  "IO+combo" = "#64A097",
  "IO+chemo" = "#D97B7B",
  "Other"    = "#9F6589",
  "Missing"  = missing_color
)

#--------------------------------------------------------------
# 2.3. Sex
#--------------------------------------------------------------

col_sex <- c(
  "F"       = "#D65B5A",
  "M"       = "#2C6AA5",
  "Missing" = missing_color
)

#--------------------------------------------------------------
# 2.4. Sample timing
#--------------------------------------------------------------

col_timing <- c(
  "Pre"     = "#125C66",
  "On"      = "#40A4B1",
  "Post"    = "#7AACB4",
  "Missing" = missing_color
)

#--------------------------------------------------------------
# 2.5. RECIST response
#--------------------------------------------------------------

col_recist <- c(
  "CR"      = "#4685A0",
  "PR"      = "#8491BE",
  "SD"      = "#BAB175",
  "PD"      = "#D65B5A",
  "NE"      = "#864568",
  "Missing" = missing_color
)

#--------------------------------------------------------------
# 2.6. Clinical metadata availability
#--------------------------------------------------------------

col_availability <- c(
  "0" = "#E1E1E1",
  "1" = "#5980AC"
)

#--------------------------------------------------------------
# 2.7. Cohort data access classification
#--------------------------------------------------------------

col_access <- c(
  "Public"            = "#6BA584",
  "Controlled access" = "#CFB385",
  "Private"           = "#C59A8B",
  "Mixed"             = "#938067",
  "Missing"           = missing_color
)

access_order <- names(col_access)


#------------------------------------------------------------------
# STEP 3. IMPORT AND VALIDATE STANDARDIZED CLINICAL DATA
#------------------------------------------------------------------
# The visualization script expects a harmonized CSV.
#
# Source-specific files, including semicolon-separated GEO files,
# must first be imported and harmonized using approved curation
# and mapping workflows.
#
# Missing values are accepted at the individual patient level
# and at the entire cohort level.
#------------------------------------------------------------------

#--------------------------------------------------------------
# 3.1. Define missing-value terminology
#--------------------------------------------------------------

missing_terms <- c(
  "",
  "na",
  "n/a",
  "null",
  "none",
  "nan",
  "unknown",
  "not available",
  "not recorded",
  "missing"
)

is_missing <- function(x) {

  y <- tolower(trimws(as.character(x)))

  is.na(x) |
    is.na(y) |
    y %in% missing_terms
}

clean_text <- function(x) {

  y <- trimws(as.character(x))

  y[is_missing(y)] <- NA_character_

  y
}

#--------------------------------------------------------------
# 3.2. Read data as character to preserve identifiers
#--------------------------------------------------------------

raw <- tryCatch(

  read.csv(
    input_file,
    header = TRUE,
    sep = ",",
    quote = "\"",
    stringsAsFactors = FALSE,
    check.names = FALSE,
    colClasses = "character",
    na.strings = character(),
    fileEncoding = "UTF-8",
    fill = FALSE
  ),

  error = function(e) {
    stop(
      "Unable to read harmonized CSV: ",
      conditionMessage(e),
      "\nCheck delimiters, quoting, and column structure.",
      call. = FALSE
    )
  }
)

if (nrow(raw) == 0) {
  stop("Input CSV contains no records.")
}

if (anyDuplicated(names(raw))) {
  stop("Duplicate column names detected in input CSV.")
}

#--------------------------------------------------------------
# 3.3. Harmonize the data access column name
#--------------------------------------------------------------

if (
  "access type" %in% names(raw) &&
  "access_type" %in% names(raw)
) {
  stop(
    "Both 'access type' and 'access_type' exist. ",
    "Resolve the duplicate upstream."
  )
}

if ("access type" %in% names(raw)) {

  names(raw)[
    names(raw) == "access type"
  ] <- "access_type"
}

#--------------------------------------------------------------
# 3.4. Validate identifiers
#--------------------------------------------------------------

required_ids <- c(
  "cohort",
  "patientid",
  "sampleid"
)

missing_ids <- setdiff(
  required_ids,
  names(raw)
)

if (length(missing_ids) > 0) {

  stop(
    "Missing required identifiers: ",
    paste(missing_ids, collapse = ", ")
  )
}

#--------------------------------------------------------------
# 3.5. Define supported optional variables
#--------------------------------------------------------------

optional_vars <- c(
  "cancer_type",
  "histo",
  "stage",
  "age",
  "sex",
  "treatment",
  "target",
  "sample_timing",
  "recist",
  "response",
  "survival_time_os",
  "event_occurred_os",
  "survival_time_pfs",
  "event_occurred_pfs",
  "rna",
  "rna_info",
  "dna",
  "dna_info",
  "access_type"
)

absent_optional <- setdiff(
  optional_vars,
  names(raw)
)

if (length(absent_optional) > 0) {

  warning(
    "Optional variables not present in the CSV: ",
    paste(absent_optional, collapse = ", "),
    ". These will be treated as unrecorded."
  )

  for (nm in absent_optional) {
    raw[[nm]] <- NA_character_
  }
}

#--------------------------------------------------------------
# 3.6. Normalize missing values
#--------------------------------------------------------------

d <- as.data.frame(
  lapply(raw, clean_text),
  check.names = FALSE,
  stringsAsFactors = FALSE
)

for (id in required_ids) {

  if (anyNA(d[[id]])) {

    stop(
      "Missing values detected in required identifier: ",
      id
    )
  }
}

# Identifiers are unique within cohort, not necessarily globally.

if (anyDuplicated(d[c("cohort", "sampleid")])) {

  stop(
    "Duplicate (cohort, sampleid) combinations detected. ",
    "Resolve before plotting."
  )
}

#--------------------------------------------------------------
# 3.7. Convert numeric clinical variables
#--------------------------------------------------------------

numeric_vars <- c(
  "age",
  "survival_time_os",
  "event_occurred_os",
  "survival_time_pfs",
  "event_occurred_pfs"
)

for (nm in numeric_vars) {

  converted <- suppressWarnings(
    as.numeric(d[[nm]])
  )

  invalid <- !is.na(d[[nm]]) &
    (is.na(converted) | !is.finite(converted))

  if (any(invalid)) {

    stop(
      "Invalid numeric values in ",
      nm,
      ": ",
      paste(
        head(unique(d[[nm]][invalid]), 5),
        collapse = ", "
      )
    )
  }

  d[[nm]] <- converted
}

#--------------------------------------------------------------
# 3.8. Validate survival event coding
#--------------------------------------------------------------
# Event indicators must already use:
#   0 = censored
#   1 = event
#
# The coding direction must be verified during source curation.
#--------------------------------------------------------------

for (nm in c(
  "event_occurred_os",
  "event_occurred_pfs"
)) {

  invalid <- !is.na(d[[nm]]) &
    !(d[[nm]] %in% c(0, 1))

  if (any(invalid)) {

    stop(
      nm,
      " must contain only 0, 1, or NA."
    )
  }
}

for (nm in c(
  "survival_time_os",
  "survival_time_pfs"
)) {

  if (any(d[[nm]] < 0, na.rm = TRUE)) {

    stop(
      "Negative survival times detected in ",
      nm
    )
  }
}

#--------------------------------------------------------------
# 3.9. Preserve original assay labels
#--------------------------------------------------------------

d$rna_source <- d$rna
d$dna_source <- d$dna

#--------------------------------------------------------------
# 3.10. Harmonize safe terminology variants
#--------------------------------------------------------------
# Only lexical differences are standardized here.
#
# Scientific interpretation and source-specific transformations
# must be completed upstream using approved mapping rules.
#
# In particular:
#   NA response != NR
#   NA assay availability != No
#   RECIST != binary response
#------------------------------------------------------------------

d <- d %>%
  mutate(

    # Sex: F / M
    sex = case_when(
      toupper(sex) %in% c("F", "FEMALE") ~ "F",
      toupper(sex) %in% c("M", "MALE") ~ "M",
      TRUE ~ sex
    ),

    # Broad cancer type labels
    cancer_type = case_when(
      tolower(cancer_type) %in%
        c("hnscc", "head and neck") ~ "Head and neck",

      tolower(cancer_type) %in%
        c("colon", "colorectal") ~ "Colorectal",

      TRUE ~ cancer_type
    ),

    # Treatment groups
    treatment = case_when(
      toupper(treatment) %in%
        c("PD-1", "PD-L1", "PD-1/PD-L1", "PD-(L)1") ~ "PD-(L)1",

      toupper(treatment) %in%
        c("CTLA-4", "CTLA4") ~ "CTLA4",

      TRUE ~ treatment
    ),

    # Sampling timepoint
    sample_timing = case_when(
      tolower(sample_timing) %in%
        c("pre", "baseline", "pretreatment",
          "pre-treatment") ~ "Pre",

      tolower(sample_timing) %in%
        c("on", "on-treatment", "on treatment") ~ "On",

      tolower(sample_timing) %in%
        c("post", "post-treatment",
          "post treatment") ~ "Post",

      TRUE ~ sample_timing
    ),

    # RECIST
    recist = toupper(recist),

    # Binary response: R / NR
    response = case_when(
      toupper(response) %in%
        c("R", "RESPONDER") ~ "R",

      toupper(response) %in%
        c("NR", "NON-RESPONDER", "NONRESPONDER") ~ "NR",

      TRUE ~ response
    ),

    # Access type
    access_type = case_when(
      tolower(access_type) == "public" ~ "Public",

      tolower(access_type) == "private" ~ "Private",

      tolower(access_type) %in%
        c("controlled", "controlled access") ~
          "Controlled access",

      TRUE ~ access_type
    ),

    # RNA availability
    # Legacy 'rnaseq' and 'microarray' indicate available RNA data.
    rna = case_when(
      tolower(rna) %in%
        c("yes", "y", "true", "1",
          "rnaseq", "rna-seq", "microarray") ~ "Yes",

      tolower(rna) %in%
        c("no", "n", "false", "0") ~ "No",

      TRUE ~ rna
    ),

    # DNA availability
    dna = case_when(
      tolower(dna) %in%
        c("yes", "y", "true", "1") ~ "Yes",

      tolower(dna) %in%
        c("no", "n", "false", "0") ~ "No",

      TRUE ~ dna
    )
  )

#--------------------------------------------------------------
# 3.11. Validate controlled categories
#--------------------------------------------------------------

validate_values <- function(x, accepted, field) {

  observed <- unique(
    na.omit(as.character(x))
  )

  unexpected <- setdiff(
    observed,
    accepted
  )

  if (length(unexpected) > 0) {

    stop(
      "Unmapped categories in ",
      field,
      ": ",
      paste(unexpected, collapse = ", "),
      "\nReview upstream harmonization and mapping rules.",
      call. = FALSE
    )
  }

  invisible(TRUE)
}

validate_values(
  d$cancer_type,
  setdiff(names(col_cancer), "Missing"),
  "cancer_type"
)

validate_values(
  d$treatment,
  setdiff(names(col_treatment), "Missing"),
  "treatment"
)

validate_values(
  d$sex,
  c("F", "M"),
  "sex"
)

validate_values(
  d$response,
  c("R", "NR"),
  "response"
)

validate_values(
  d$recist,
  c("CR", "PR", "SD", "PD", "NE"),
  "recist"
)

validate_values(
  d$sample_timing,
  c("Pre", "On", "Post"),
  "sample_timing"
)

validate_values(
  d$rna,
  c("Yes", "No"),
  "rna"
)

validate_values(
  d$dna,
  c("Yes", "No"),
  "dna"
)

validate_values(
  d$access_type,
  c("Public", "Controlled access", "Private"),
  "access_type"
)


#------------------------------------------------------------------
# STEP 4. CONSTRUCT PATIENT-LEVEL METADATA
#------------------------------------------------------------------
# One patient may have multiple samples.
#
# For patient-level plots:
#   - Count each cohort-patient once.
#   - Preserve valid observations.
#   - Identify conflicting patient-level records.
#   - Assign NA to unresolved conflicting values.
#
# No conflicting values are automatically selected.
#------------------------------------------------------------------

patient_fields <- c(
  "cancer_type",
  "histo",
  "stage",
  "age",
  "sex",
  "treatment",
  "target",
  "recist",
  "response",
  "survival_time_os",
  "event_occurred_os",
  "survival_time_pfs",
  "event_occurred_pfs"
)

count_distinct_observed <- function(x) {

  length(
    unique(x[!is_missing(x)])
  )
}

first_unambiguous <- function(x) {

  values <- unique(
    x[!is_missing(x)]
  )

  if (length(values) == 1) {
    return(values[[1]])
  }

  # Typed NA preserves numeric/character class.
  x[NA_integer_][1]
}

#--------------------------------------------------------------
# 4.1. Identify conflicting patient-level values
#--------------------------------------------------------------

conflicts <- d %>%
  group_by(cohort, patientid) %>%
  summarise(
    across(
      all_of(patient_fields),
      count_distinct_observed
    ),
    .groups = "drop"
  ) %>%
  pivot_longer(
    cols = all_of(patient_fields),
    names_to = "field",
    values_to = "n_distinct"
  ) %>%
  filter(n_distinct > 1) %>%
  arrange(cohort, patientid, field)

write.csv(
  conflicts,
  file.path(outdir, "patient_level_conflicts.csv"),
  row.names = FALSE,
  na = ""
)

if (nrow(conflicts) > 0) {

  warning(
    nrow(conflicts),
    " conflicting patient-field combinations detected. ",
    "See patient_level_conflicts.csv."
  )
}

#--------------------------------------------------------------
# 4.2. Generate unique cohort-patient table
#--------------------------------------------------------------

p <- d %>%
  group_by(cohort, patientid) %>%
  summarise(
    across(
      all_of(patient_fields),
      first_unambiguous
    ),
    .groups = "drop"
  )

#--------------------------------------------------------------
# 4.3. Define stable cohort order
#--------------------------------------------------------------

cohort_counts <- d %>%
  count(cohort, name = "n_samples") %>%
  arrange(desc(n_samples), cohort)

base_order <- cohort_counts$cohort

d$cohort <- factor(
  d$cohort,
  levels = rev(base_order)
)

p$cohort <- factor(
  p$cohort,
  levels = rev(base_order)
)


#------------------------------------------------------------------
# STEP 5. COHORT SUMMARY AND MISSINGNESS REPORTING
#------------------------------------------------------------------
# Export the underlying numbers used to characterize cohorts.
#
# Missingness is calculated independently for sample-level and
# patient-level metadata.
#
# Entirely missing variables are retained in the reports.
#------------------------------------------------------------------

missingness_fields <- c(
  "cancer_type",
  "histo",
  "stage",
  "age",
  "sex",
  "treatment",
  "sample_timing",
  "recist",
  "response",
  "survival_time_os",
  "event_occurred_os",
  "survival_time_pfs",
  "event_occurred_pfs",
  "rna",
  "dna"
)

#--------------------------------------------------------------
# 5.1. Missingness reporting function
#--------------------------------------------------------------

missingness_report <- function(tbl, fields, unit) {

  tbl %>%
    mutate(
      across(
        all_of(fields),
        ~ is_missing(.x)
      )
    ) %>%
    group_by(cohort) %>%
    summarise(
      across(
        all_of(fields),
        ~ sum(.x),
        .names = "{.col}"
      ),
      n_records = n(),
      .groups = "drop"
    ) %>%
    pivot_longer(
      cols = all_of(fields),
      names_to = "variable",
      values_to = "n_missing"
    ) %>%
    mutate(
      unit = unit,
      n_observed = n_records - n_missing,
      pct_missing = round(
        100 * n_missing / n_records,
        2
      ),
      availability = ifelse(
        n_observed > 0,
        "Yes",
        "No"
      )
    ) %>%
    select(
      cohort,
      unit,
      variable,
      n_records,
      n_observed,
      n_missing,
      pct_missing,
      availability
    )
}

#--------------------------------------------------------------
# 5.2. Sample-level missingness
#--------------------------------------------------------------

missing_samples <- missingness_report(
  d,
  missingness_fields,
  "sample"
)

#--------------------------------------------------------------
# 5.3. Patient-level missingness
#--------------------------------------------------------------

missing_patients <- missingness_report(
  p,
  intersect(missingness_fields, names(p)),
  "cohort-patient"
)

write.csv(
  bind_rows(
    missing_samples,
    missing_patients
  ) %>%
    mutate(cohort = as.character(cohort)),
  file.path(outdir, "cohort_variable_missingness.csv"),
  row.names = FALSE,
  na = ""
)

#--------------------------------------------------------------
# 5.4. Record original RNA/DNA assay notation
#--------------------------------------------------------------

assay_labels <- d %>%
  count(
    cohort,
    rna_source,
    rna,
    dna_source,
    dna,
    name = "n_samples"
  )

write.csv(
  assay_labels %>%
    mutate(cohort = as.character(cohort)),
  file.path(outdir, "assay_source_labels.csv"),
  row.names = FALSE,
  na = ""
)

#--------------------------------------------------------------
# 5.5. Generate cohort summary
#--------------------------------------------------------------

cohort_summary <- d %>%
  group_by(cohort) %>%
  summarise(

    samples = n_distinct(sampleid),

    patients = n_distinct(patientid),

    cancer_types = paste(
      sort(unique(na.omit(cancer_type))),
      collapse = " | "
    ),

    treatments = paste(
      sort(unique(na.omit(treatment))),
      collapse = " | "
    ),

    rna_yes_samples = sum(
      rna == "Yes",
      na.rm = TRUE
    ),

    dna_yes_samples = sum(
      dna == "Yes",
      na.rm = TRUE
    ),

    rna_unknown_samples = sum(is.na(rna)),

    dna_unknown_samples = sum(is.na(dna)),

    pre_samples = sum(
      sample_timing == "Pre",
      na.rm = TRUE
    ),

    on_samples = sum(
      sample_timing == "On",
      na.rm = TRUE
    ),

    post_samples = sum(
      sample_timing == "Post",
      na.rm = TRUE
    ),

    .groups = "drop"
  )

write.csv(
  cohort_summary,
  file.path(outdir, "cohort_summary.csv"),
  row.names = FALSE,
  na = ""
)


#------------------------------------------------------------------
# STEP 6. SAMPLE-WEIGHTED CANCER AND TREATMENT DONUT CHARTS
#------------------------------------------------------------------
# Each sample contributes once to the relevant distribution.
#
# The label position is calculated using the same stacking
# algorithm as the donut segments.
#
# Slices below 3% retain their counts and legend categories,
# but their labels are suppressed to avoid overlap.
#------------------------------------------------------------------

donut <- function(df, field, title, stem, colors) {

  #--------------------------------------------------------------
  # 6.1. Prepare counts
  #--------------------------------------------------------------

  tab <- df %>%
    mutate(
      category = ifelse(
        is.na(.data[[field]]),
        "Missing",
        .data[[field]]
      )
    ) %>%
    count(category, name = "n") %>%
    arrange(desc(n), category) %>%
    mutate(
      percent = 100 * n / sum(n),

      label = ifelse(
        percent >= 3,
        paste0(round(percent), "%"),
        ""
      )
    )

  tab$category <- factor(
    tab$category,
    levels = as.character(tab$category)
  )

  #--------------------------------------------------------------
  # 6.2. Export underlying category counts
  #--------------------------------------------------------------

  write.csv(
    tab %>%
      mutate(category = as.character(category)),
    file.path(outdir, paste0(stem, "_counts.csv")),
    row.names = FALSE
  )

  #--------------------------------------------------------------
  # 6.3. Generate donut chart
  #--------------------------------------------------------------

  plt <- ggplot(
    tab,
    aes(
      x = 2,
      y = n,
      fill = category
    )
  ) +

    geom_col(
      width = 0.70,
      color = "white",
      linewidth = 0.6
    ) +

    geom_text(
      aes(
        label = label,
        group = category
      ),
      position = position_stack(
        vjust = 0.5
      ),
      color = "white",
      size = 4.3,
      fontface = "bold"
    ) +

    coord_polar(theta = "y") +

    xlim(0.5, 2.5) +

    scale_fill_manual(
      values = colors,
      breaks = levels(tab$category),
      drop = TRUE
    ) +

    labs(
      title = title,
      fill = NULL
    ) +

    theme_void(base_size = 12) +

    theme(
      plot.title = element_text(
        face = "bold",
        hjust = 0.5,
        size = 14
      ),

      legend.position = "right",

      legend.text = element_text(
        size = 10
      ),

      plot.background = element_rect(
        fill = "white",
        colour = NA
      )
    )

  #--------------------------------------------------------------
  # 6.4. Save and display
  #--------------------------------------------------------------

  ggsave(
    filename = file.path(
      outdir,
      paste0(stem, ".png")
    ),
    plot = plt,
    width = 8,
    height = 6,
    dpi = 300,
    bg = "white"
  )

  if (interactive()) {
    print(plt)
  }

  invisible(plt)
}

#--------------------------------------------------------------
# 6.5. Cancer type distribution
#--------------------------------------------------------------

plot_cancer <- donut(
  d,
  "cancer_type",
  "Cancer type distribution",
  "01_cancer_donut",
  col_cancer
)

#--------------------------------------------------------------
# 6.6. Immunotherapy treatment distribution
#--------------------------------------------------------------

plot_treatment <- donut(
  d,
  "treatment",
  "Immunotherapy treatment distribution",
  "02_treatment_donut",
  col_treatment
)


#------------------------------------------------------------------
# STEP 7. SEX, SAMPLE TIMING, AND RECIST DISTRIBUTIONS
#------------------------------------------------------------------
# Generate 100% stacked horizontal bar charts.
#
# Sex and RECIST use unique cohort-patients.
# Sampling timing uses individual samples.
#
# Missing values remain visible as a separate category.
#------------------------------------------------------------------

stack_plot <- function(df, field, stem, colors, unit) {

  #--------------------------------------------------------------
  # 7.1. Calculate category proportions
  #--------------------------------------------------------------

  tab <- df %>%
    mutate(
      category = ifelse(
        is.na(.data[[field]]),
        "Missing",
        .data[[field]]
      )
    ) %>%
    count(
      cohort,
      category,
      name = "n"
    ) %>%
    group_by(cohort) %>%
    mutate(
      percent = 100 * n / sum(n)
    ) %>%
    ungroup()

  #--------------------------------------------------------------
  # 7.2. Export plot data
  #--------------------------------------------------------------

  write.csv(
    tab %>%
      mutate(cohort = as.character(cohort)),
    file.path(outdir, paste0(stem, "_counts.csv")),
    row.names = FALSE
  )

  #--------------------------------------------------------------
  # 7.3. Verify proportions
  #--------------------------------------------------------------

  pct_check <- tab %>%
    group_by(cohort) %>%
    summarise(
      pct_sum = sum(percent),
      .groups = "drop"
    )

  stopifnot(
    all(abs(pct_check$pct_sum - 100) < 1e-7)
  )

  #--------------------------------------------------------------
  # 7.4. Generate plot
  #--------------------------------------------------------------

  plt <- ggplot(
    tab,
    aes(
      y = cohort,
      x = percent,
      fill = category
    )
  ) +

    geom_col(
      width = 0.72,
      color = "white",
      linewidth = 0.3
    ) +

    scale_fill_manual(
      values = colors,
      limits = names(colors),
      drop = TRUE
    ) +

    scale_x_continuous(
      limits = c(0, 100),
      breaks = seq(0, 100, 25),
      expand = expansion(
        mult = c(0, 0)
      )
    ) +

    labs(
      x = paste0(
        "% of ",
        tolower(unit)
      ),
      y = NULL,
      fill = NULL
    ) +

    theme_minimal(base_size = 12) +

    theme(
      panel.grid.major.y = element_blank(),
      panel.grid.minor = element_blank(),
      legend.position = "bottom"
    )

  # Adjust figure height to cohort count.
  plot_height <- max(
    5,
    2.5 + 0.36 * n_distinct(df$cohort)
  )

  #--------------------------------------------------------------
  # 7.5. Save and display
  #--------------------------------------------------------------

  ggsave(
    filename = file.path(
      outdir,
      paste0(stem, ".png")
    ),
    plot = plt,
    width = 10,
    height = plot_height,
    dpi = 300,
    bg = "white"
  )

  if (interactive()) {
    print(plt)
  }

  invisible(plt)
}

#--------------------------------------------------------------
# 7.6. Sex by cohort
#--------------------------------------------------------------

plot_sex <- stack_plot(
  p,
  "sex",
  "04_sex_by_cohort",
  col_sex,
  "Patients"
)

#--------------------------------------------------------------
# 7.7. Sample timing by cohort
#--------------------------------------------------------------

plot_timing <- stack_plot(
  d,
  "sample_timing",
  "05_sampling_timing_by_cohort",
  col_timing,
  "Samples"
)

#--------------------------------------------------------------
# 7.8. RECIST by cohort
#--------------------------------------------------------------

plot_recist <- stack_plot(
  p,
  "recist",
  "06_recist_by_cohort",
  col_recist,
  "Patients"
)


#------------------------------------------------------------------
# STEP 8. CLINICAL METADATA AVAILABILITY HEATMAP
#------------------------------------------------------------------
# ComplexHeatmap displays six variables:
#
#   Age, Sex, Stage, Response, OS, PFS
#
# Availability:
#   Yes = at least one cohort-patient has an observed value.
#   No  = no cohort-patients have an observed value.
#
# For OS/PFS, this descriptive check uses time OR event.
# This does NOT mean the endpoint is analysis-ready.
#
# Data access is shown as a separate annotation.
#
# Cohorts are ordered:
#   Public -> Controlled access -> Private -> Mixed -> Missing
#------------------------------------------------------------------

#--------------------------------------------------------------
# 8.1. Define availability function
#--------------------------------------------------------------

observed <- function(x) {
  any(!is_missing(x))
}

#--------------------------------------------------------------
# 8.2. Calculate clinical availability per cohort
#--------------------------------------------------------------

clinical_av <- p %>%
  group_by(cohort) %>%
  summarise(

    Age = observed(age),

    Sex = observed(sex),

    Stage = observed(stage),

    Response = observed(response),

    OS = any(
      !is.na(survival_time_os) |
        !is.na(event_occurred_os)
    ),

    PFS = any(
      !is.na(survival_time_pfs) |
        !is.na(event_occurred_pfs)
    ),

    .groups = "drop"
  )

variable_order <- c(
  "Age",
  "Sex",
  "Stage",
  "Response",
  "OS",
  "PFS"
)

#--------------------------------------------------------------
# 8.3. Classify cohort access
#--------------------------------------------------------------

access_summary <- d %>%
  group_by(cohort) %>%
  summarise(

    Access = {

      access_values <- unique(
        na.omit(access_type)
      )

      if (length(access_values) == 0) {

        "Missing"

      } else if (
        length(access_values) == 1 &&
        all(!is.na(access_type))
      ) {

        access_values[[1]]

      } else {

        "Mixed"
      }
    },

    samples = n_distinct(sampleid),

    .groups = "drop"
  ) %>%
  mutate(
    cohort = as.character(cohort),

    Access = factor(
      Access,
      levels = access_order
    )
  ) %>%
  arrange(
    Access,
    desc(samples),
    cohort
  )

cohort_order <- access_summary$cohort

access_vector <- as.character(
  access_summary$Access
)

names(access_vector) <- cohort_order

#--------------------------------------------------------------
# 8.4. Generate availability matrix
#--------------------------------------------------------------

availability_long <- clinical_av %>%
  mutate(
    cohort = as.character(cohort)
  ) %>%
  pivot_longer(
    cols = all_of(variable_order),
    names_to = "variable",
    values_to = "available"
  )

av_matrix <- matrix(
  0,
  nrow = length(variable_order),
  ncol = length(cohort_order),

  dimnames = list(
    variable_order,
    cohort_order
  )
)

for (i in seq_len(nrow(availability_long))) {

  av_matrix[
    availability_long$variable[i],
    availability_long$cohort[i]
  ] <- as.integer(
    availability_long$available[i]
  )
}

if (
  anyNA(av_matrix) ||
  ncol(av_matrix) != n_distinct(d$cohort)
) {

  stop(
    "Clinical availability matrix does not match cohort records."
  )
}

#--------------------------------------------------------------
# 8.5. Define access annotation
#--------------------------------------------------------------

ha <- ComplexHeatmap::HeatmapAnnotation(

  Access = access_vector,

  col = list(
    Access = col_access
  ),

  annotation_name_side = "left",

  simple_anno_size = grid::unit(
    5,
    "mm"
  ),

  annotation_legend_param = list(
    Access = list(
      title = "Access type"
    )
  )
)

#--------------------------------------------------------------
# 8.6. Generate heatmap object
#--------------------------------------------------------------

ht <- ComplexHeatmap::Heatmap(

  av_matrix,

  name = "Availability",

  col = col_availability,

  top_annotation = ha,

  cluster_rows = FALSE,

  cluster_columns = FALSE,

  row_names_gp = grid::gpar(
    fontsize = 10
  #  fontface = "bold"
  ),

  column_names_gp = grid::gpar(
    fontsize = 9
  ),

  column_names_rot = 45,

  rect_gp = grid::gpar(
    col = "#B8C1CC",
    lwd = 0.6
  ),

  border = TRUE,

  heatmap_legend_param = list(
    at = c(0, 1),
    labels = c("No", "Yes"),
    title = "Availability"
  )
)

#--------------------------------------------------------------
# 8.7. Render heatmap
#--------------------------------------------------------------

draw_heatmap <- function() {

  ComplexHeatmap::draw(
    ht,
    heatmap_legend_side = "right",
    annotation_legend_side = "right",
    merge_legends = TRUE
  )
}

with_device <- function(open_device, render) {

  open_device()

  on.exit(
    grDevices::dev.off(),
    add = TRUE
  )

  render()
}

# Scale figure width according to number of cohorts.
heatmap_width <- max(
  9,
  5 + 0.48 * length(cohort_order)
)

#--------------------------------------------------------------
# 8.8. Export PDF
#--------------------------------------------------------------

with_device(
  function() {
    grDevices::pdf(
      file.path(
        outdir,
        "03_clinical_availability_heatmap.pdf"
      ),
      width = heatmap_width,
      height = 3.5
    )
  },
  draw_heatmap
)

#--------------------------------------------------------------
# 8.9. Export PNG
#--------------------------------------------------------------

with_device(
  function() {
    grDevices::png(
      file.path(
        outdir,
        "03_clinical_availability_heatmap.png"
      ),
      width = round(heatmap_width * 250),
      height = 875,
      res = 250,
      bg = "white"
    )
  },
  draw_heatmap
)

if (interactive()) {
  draw_heatmap()
}

#--------------------------------------------------------------
# 8.10. Export clinical availability and access summaries
#--------------------------------------------------------------

clinical_av_export <- clinical_av %>%
  mutate(
    cohort = as.character(cohort)
  ) %>%
  mutate(
    across(
      all_of(variable_order),
      ~ ifelse(.x, "Yes", "No")
    )
  ) %>%
  left_join(
    access_summary %>%
      mutate(
        Access = as.character(Access)
      ),
    by = "cohort"
  ) %>%
  arrange(
    match(cohort, cohort_order)
  )

write.csv(
  clinical_av_export,
  file.path(
    outdir,
    "cohort_clinical_availability.csv"
  ),
  row.names = FALSE
)

write.csv(
  access_summary %>%
    mutate(
      Access = as.character(Access)
    ),
  file.path(
    outdir,
    "cohort_access_summary.csv"
  ),
  row.names = FALSE
)

unavailable_variables <- clinical_av_export %>%
  pivot_longer(
    cols = all_of(variable_order),
    names_to = "variable",
    values_to = "status"
  ) %>%
  filter(
    status == "No"
  )

write.csv(
  unavailable_variables,
  file.path(
    outdir,
    "cohort_unavailable_variables.csv"
  ),
  row.names = FALSE
)


#------------------------------------------------------------------
# STEP 9. SURVIVAL DATA COMPLETENESS AND OBSERVED TIMES
#------------------------------------------------------------------
# Calculate descriptive summaries only.
#
# These are NOT Kaplan-Meier survival estimates and are NOT
# median follow-up based on reverse Kaplan-Meier.
#
# Survival-analysis readiness also requires review of endpoint
# definitions, time origins, censoring, and study comparability.
#------------------------------------------------------------------

safe_median <- function(x) {

  if (all(is.na(x))) {
    return(NA_real_)
  }

  median(
    x,
    na.rm = TRUE
  )
}

followup <- p %>%
  group_by(cohort) %>%
  summarise(

    os_time_n = sum(
      !is.na(survival_time_os)
    ),

    os_paired_n = sum(
      !is.na(survival_time_os) &
        !is.na(event_occurred_os)
    ),

    os_observed_time_median = safe_median(
      survival_time_os
    ),

    pfs_time_n = sum(
      !is.na(survival_time_pfs)
    ),

    pfs_paired_n = sum(
      !is.na(survival_time_pfs) &
        !is.na(event_occurred_pfs)
    ),

    pfs_observed_time_median = safe_median(
      survival_time_pfs
    ),

    .groups = "drop"
  )

write.csv(
  followup,
  file.path(
    outdir,
    "observed_followup_summary.csv"
  ),
  row.names = FALSE,
  na = ""
)


#------------------------------------------------------------------
# STEP 10. RECORD REPRODUCIBILITY INFORMATION
#------------------------------------------------------------------
# Store:
#   Input file and checksum
#   Execution date
#   Git commit
#   Cohort/sample/patient counts
#   Analysis conventions
#   Package and R versions
#
# This manifest documents the analysis run; it is not an
# authorization to distribute restricted input data.
#------------------------------------------------------------------

#--------------------------------------------------------------
# 10.1. Obtain Git commit when available
#--------------------------------------------------------------

git_hash <- tryCatch({

  result <- suppressWarnings(
    system2(
      "git",
      c("rev-parse", "HEAD"),
      stdout = TRUE,
      stderr = FALSE
    )
  )

  if (
    length(result) > 0 &&
    is.null(attr(result, "status"))
  ) {
    result[[1]]
  } else {
    "unavailable"
  }

}, error = function(e) {
  "unavailable"
})

#--------------------------------------------------------------
# 10.2. Assemble run manifest
#--------------------------------------------------------------

manifest <- c(

  "MAR-40 cohort visualization | Version 1.1",

  paste0(
    "Input file: ",
    normalizePath(input_file)
  ),

  paste0(
    "Input MD5: ",
    unname(tools::md5sum(input_file))
  ),

  paste0(
    "Output directory: ",
    normalizePath(outdir)
  ),

  paste0(
    "Timestamp: ",
    format(
      Sys.time(),
      "%Y-%m-%d %H:%M:%S %Z"
    )
  ),

  paste0(
    "Git commit: ",
    git_hash
  ),

  paste0(
    "Cohorts: ",
    n_distinct(d$cohort)
  ),

  paste0(
    "Samples: ",
    nrow(d)
  ),

  paste0(
    "Cohort-patients: ",
    nrow(p)
  ),

  "Patient unit: unique (cohort, patientid)",

  "Cancer and treatment donuts: sample-level",

  "Sex and RECIST: cohort-patient-level",

  "Sampling timing: sample-level",

  "Clinical availability: any observed value",

  "OS/PFS availability: time OR event",

  "Missing observations are not negative observations",

  "Unresolved patient-level conflicts are represented as NA",

  "Sex notation: F / M",

  "Binary response notation: R / NR",

  "RECIST notation: CR / PR / SD / PD / NE",

  "Access ordering: Public / Controlled access / Private / Mixed / Missing",

  "Survival units and endpoint definitions must be harmonized upstream",

  capture.output(
    sessionInfo()
  )
)

#--------------------------------------------------------------
# 10.3. Save run manifest
#--------------------------------------------------------------

writeLines(
  manifest,
  file.path(
    outdir,
    "run_manifest.txt"
  )
)

#--------------------------------------------------------------
# 10.4. Final execution summary
#--------------------------------------------------------------

message(
  "MAR-40 visualization completed successfully."
)

message(
  "Cohorts: ",
  n_distinct(d$cohort)
)

message(
  "Samples: ",
  nrow(d)
)

message(
  "Cohort-patients: ",
  nrow(p)
)

message(
  "Results saved to: ",
  normalizePath(outdir)
)
