#!/usr/bin/env Rscript
# ============================================================
# MAR-40 | ICB_Hwang Clinical Metadata Harmonization (GSE136961)
# ============================================================
# Inputs:
#   data/examples/icb_hwang/curation/
#     CLIN.txt
#
#   data/examples/icb_hwang/annot/
#     curation_tissue.csv
#
# Output:
#   data/examples/icb_hwang/curation/
#     CLIN.csv (semicolon-delimited)
#
# Usage:
#   Rscript workflow/icb_hwang/scripts/Format_CLIN.R
#
# Optional:
#   Rscript workflow/icb_hwang/scripts/Format_CLIN.R \
#     data/examples/icb_hwang
#
# Purpose:
#   Harmonize Hwang clinical metadata according to the
#   common ICB format while preserving original GEO fields.
#
# Notes:
#   - Patient identifiers follow GEO GSM accessions.
#   - Histology is harmonized using tissue annotations.
#   - Survival times are converted from days to months.
#   - Source recurrence status is stored in 'pfs'.
#   - The study used nivolumab OR pembrolizumab (anti-PD-1).
#   - Individual drug assignments are not established.
#   - Get_Response() may derive response from PFS.
#   - Missing clinical values are preserved as NA.
# ============================================================

suppressPackageStartupMessages({
  library(stringr)
  library(tibble)
})

# ------------------------------------------------------------
# 1. Define directories
# ------------------------------------------------------------

args <- commandArgs(trailingOnly = TRUE)

data_root <- if (length(args) >= 1) {
  args[1]
} else {
  "data/examples/icb_hwang"
}

input_dir <- file.path(data_root, "curation")
output_dir <- file.path(data_root, "curation")
annot_dir <- file.path(data_root, "annot")

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

clin_input <- file.path(input_dir, "CLIN.txt")
tissue_input <- file.path(annot_dir, "curation_tissue.csv")
clin_output <- file.path(output_dir, "CLIN.csv")

# ------------------------------------------------------------
# 2. Validate input files
# ------------------------------------------------------------

for (f in c(clin_input, tissue_input)) {
  if (!file.exists(f)) {
    stop("Required input file not found: ", f)
  }
}

# ------------------------------------------------------------
# 3. Load shared ICB harmonization functions
# ------------------------------------------------------------

message("Loading shared ICB harmonization functions...")

source(
  "https://raw.githubusercontent.com/BHKLAB-Pachyderm/ICB_Common/main/code/Get_Response.R"
)

source(
  "https://raw.githubusercontent.com/BHKLAB-Pachyderm/ICB_Common/main/code/annotate_tissue.R"
)

# ------------------------------------------------------------
# 4. Read GEO clinical metadata
# ------------------------------------------------------------

message("Reading GEO clinical metadata...")

clin_raw <- read.csv(
  clin_input,
  stringsAsFactors = FALSE,
  sep = "\t",
  header = TRUE,
  check.names = FALSE
)

required_cols <- c(
  "geo_accession",
  "Sex_ch1",
  "tumor_type_ch1",
  "survival_ch1"
)

if (!all(required_cols %in% colnames(clin_raw))) {
  stop(
    "Missing required GEO columns: ",
    paste(
      setdiff(required_cols, colnames(clin_raw)),
      collapse = ", "
    )
  )
}

if (anyNA(clin_raw$geo_accession) ||
    anyDuplicated(clin_raw$geo_accession)) {
  stop("GEO accessions must be unique and nonmissing.")
}

message("Clinical samples loaded: ", nrow(clin_raw))

# ------------------------------------------------------------
# 5. Initialize standardized clinical variables
# ------------------------------------------------------------

selected_cols <- c(
  "patient", "sex", "primary", "recist", "drug_type",
  "t.os", "t.pfs", "histo", "stage", "age", "os",
  "pfs", "dna", "dna_info", "rna", "rna_info",
  "response.other.info", "response"
)

clin <- clin_raw

new_cols <- setdiff(
  selected_cols,
  colnames(clin)
)

clin[new_cols] <- NA

# ------------------------------------------------------------
# 6. Harmonize patient, tissue and treatment information
# ------------------------------------------------------------

message("Harmonizing clinical variables...")

# GEO sample accession is used as the legacy ICB patient key.

clin$patient <- as.character(clin_raw$geo_accession)

# Sex

clin$sex <- ifelse(
  tolower(trimws(clin_raw$Sex_ch1)) == "female",
  "F",
  ifelse(
    tolower(trimws(clin_raw$Sex_ch1)) == "male",
    "M",
    NA_character_
  )
)

# Cancer type and treatment class

clin$primary <- "Lung"
clin$drug_type <- "PD-1"

# Expression assay information
# Preserve original ICB curation conventions.

clin$rna <- "rnaseq"
clin$rna_info <- "tpm"

# Histology mapping

histo_map <- c(
  "adenocarcinoma" =
    "Lung Adenocarcinoma",
  "adenocarcinoma-squamous cell carcinoma" =
    "Lung Adenosquamous Carcinoma",
  "Large cell neuroendocarine carcinoma" =
    "Lung Large Cell Neuroendocrine Carcinoma",
  "squamous cell carcinoma" =
    "Lung Squamous Cell Carcinoma"
)

clin$histo <- unname(
  histo_map[clin_raw$tumor_type_ch1]
)

# ------------------------------------------------------------
# 7. Harmonize survival information
# ------------------------------------------------------------

message("Processing survival information...")

# Example:
# recurrence:1, progression-free-survival_days:144,
# live, overall-survival_days:234

survival <- stringr::str_split(
  clin_raw$survival_ch1,
  ","
)

# PFS event indicator

clin$pfs <- as.numeric(
  vapply(
    survival,
    function(s) {
      if (length(s) < 1) {
        return(NA_character_)
      }

      stringr::str_extract(s[1], "\\d+")
    },
    character(1)
  )
)

# PFS time in months

clin$t.pfs <- as.numeric(
  vapply(
    survival,
    function(s) {
      if (length(s) < 2) {
        return(NA_character_)
      }

      stringr::str_extract(s[2], "\\d+")
    },
    character(1)
  )
) / 30.5

# OS event indicator

clin$os <- vapply(
  survival,
  function(s) {
    if (length(s) < 3) {
      return(NA_real_)
    }

    status <- tolower(
      stringr::str_trim(s[3])
    )

    if (status == "live") {
      return(0)
    }

    if (status == "dead") {
      return(1)
    }

    NA_real_
  },
  numeric(1)
)

# OS time in months

clin$t.os <- as.numeric(
  vapply(
    survival,
    function(s) {
      if (length(s) < 4) {
        return(NA_character_)
      }

      stringr::str_extract(s[4], "\\d+")
    },
    character(1)
  )
) / 30.5

# ------------------------------------------------------------
# 8. Add response annotation
# ------------------------------------------------------------

message("Annotating treatment response...")

clin$response <- Get_Response(
  data = clin
)

# ------------------------------------------------------------
# 9. Add tissue annotation
# ------------------------------------------------------------

message("Annotating tissue information...")

annotation_tissue <- read.csv(
  tissue_input,
  stringsAsFactors = FALSE
)

clin <- annotate_tissue(
  clin = clin,
  study = "Hwang",
  annotation_tissue = annotation_tissue,
  check_histo = FALSE
)

# ------------------------------------------------------------
# 10. Add study-reported treatment options
# ------------------------------------------------------------

# Individual patient treatment assignments are unavailable.
# This field records the study's reported treatment options,
# not combined therapy for every patient.

if ("treatmentid" %in% colnames(clin)) {
  clin$treatmentid <- "Nivolumab|Pembrolizumab"
} else if ("tissueid" %in% colnames(clin)) {
  clin <- tibble::add_column(
    clin,
    treatmentid = "Nivolumab|Pembrolizumab",
    .after = "tissueid"
  )
} else {
  clin$treatmentid <- "Nivolumab|Pembrolizumab"
}

# ------------------------------------------------------------
# 11. Organize clinical columns
# ------------------------------------------------------------

# Preserve the original GEO fields.
# Place the common ICB variables first.

clin <- clin[
  ,
  c(
    selected_cols,
    setdiff(colnames(clin), selected_cols)
  ),
  drop = FALSE
]

# Validate identifier used by the MAE pipeline.

if (!"patient" %in% colnames(clin)) {
  stop("Required patient column is missing.")
}

if (anyNA(clin$patient) || anyDuplicated(clin$patient)) {
  stop("Clinical patient identifiers must be unique and nonmissing.")
}

# ------------------------------------------------------------
# 12. Export harmonized clinical metadata
# ------------------------------------------------------------

write.table(
  clin,
  file = clin_output,
  quote = FALSE,
  sep = ";",
  col.names = TRUE,
  row.names = FALSE,
  na = "NA"
)

message("Clinical metadata saved: ", clin_output)
message("Clinical samples: ", nrow(clin))
message("Clinical variables: ", ncol(clin))
message("Clinical harmonization completed successfully.")