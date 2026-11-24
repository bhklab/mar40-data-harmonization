#!/usr/bin/env Rscript
# ============================================================
# MAR-40 | ICB_Hwang Molecular Data Availability (GSE136961)
# ============================================================
# Inputs:
#   data/examples/icb_hwang/curation/
#     CLIN.txt
#     EXP_TPM.tsv
#
# Output:
#   data/examples/icb_hwang/curation/
#     cased_sequenced.csv (semicolon-delimited)
#
# Usage:
#   Rscript workflow/scripts/icb_hwang/Format_cased_sequenced.R
#
# Optional:
#   Rscript workflow/scripts/icb_hwang/Format_cased_sequenced.R \
#     data/examples/icb_hwang
#
# Purpose:
#   Generate sample-level molecular data availability flags
#   for the Hwang cohort following the common ICB format.
#
# Variables:
#   patient : GEO sample accession (GSM identifier)
#   snv     : SNV data availability (0/1)
#   cna     : CNA data availability (0/1)
#   expr    : RNA expression data availability (0/1)
#
# Notes:
#   - RNA availability is verified against EXP_TPM.tsv.
#   - SNV and CNA files are not provided in this example.
#   - 1 = data available in this curated dataset.
#   - 0 = data not available in this curated dataset.
#   - 0 does not imply biological absence of alterations.
#   - Original GEO source files remain unchanged.
# ============================================================

suppressPackageStartupMessages({
  library(data.table)
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

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

clin_input <- file.path(input_dir, "CLIN.txt")
expr_input <- file.path(input_dir, "EXP_TPM.tsv")

case_output <- file.path(
  output_dir,
  "cased_sequenced.csv"
)

# ------------------------------------------------------------
# 2. Validate input files
# ------------------------------------------------------------

for (f in c(clin_input, expr_input)) {
  if (!file.exists(f)) {
    stop("Required input file not found: ", f)
  }
}

# ------------------------------------------------------------
# 3. Read clinical metadata
# ------------------------------------------------------------

message("Reading clinical metadata...")

clin <- data.table::fread(
  clin_input,
  sep = "\t",
  header = TRUE,
  check.names = FALSE
)

if (!"geo_accession" %in% colnames(clin)) {
  stop("Required column 'geo_accession' is missing.")
}

patient <- sort(
  unique(as.character(clin$geo_accession))
)

patient <- patient[
  !is.na(patient) & nzchar(trimws(patient))
]

if (length(patient) == 0) {
  stop("No valid GEO sample accessions found.")
}

# ------------------------------------------------------------
# 4. Read RNA sample identifiers
# ------------------------------------------------------------

message("Reading RNA expression sample identifiers...")

# Read only the header to avoid loading the full matrix.
expr_header <- names(
  data.table::fread(
    expr_input,
    sep = "\t",
    header = TRUE,
    nrows = 0,
    check.names = FALSE
  )
)

if (!"Symbol_ID" %in% expr_header) {
  stop("Required column 'Symbol_ID' is missing.")
}

expr_samples <- setdiff(
  expr_header,
  "Symbol_ID"
)

if (anyDuplicated(expr_samples)) {
  stop("Duplicate sample identifiers in expression matrix.")
}

# ------------------------------------------------------------
# 5. Define molecular data availability
# ------------------------------------------------------------

message("Assigning molecular data availability...")

# The Hwang example provides an RNA expression dataset.
# SNV/CNA files are not part of the curated example.

case <- data.frame(
  patient = patient,
  snv = 0L,
  cna = 0L,
  expr = as.integer(patient %in% expr_samples),
  stringsAsFactors = FALSE
)

# Check that RNA sample identifiers match clinical records.
unmatched_expr <- setdiff(expr_samples, patient)

if (length(unmatched_expr) > 0) {
  stop(
    "RNA samples missing from clinical metadata: ",
    paste(unmatched_expr, collapse = ", ")
  )
}

message("Total clinical samples: ", nrow(case))
message("RNA available: ", sum(case$expr == 1L))
message("RNA unavailable: ", sum(case$expr == 0L))

# ------------------------------------------------------------
# 6. Export molecular availability
# ------------------------------------------------------------

data.table::fwrite(
  case,
  file = case_output,
  sep = ";",
  quote = FALSE,
  na = "NA"
)

message("Sequencing availability saved: ", case_output)
message("Molecular availability completed successfully.")
