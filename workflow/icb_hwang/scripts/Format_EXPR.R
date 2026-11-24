#!/usr/bin/env Rscript
# ============================================================
# MAR-40 | ICB_Hwang Gene Expression Harmonization (GSE136961)
# ============================================================
# Inputs:
#   data/examples/icb_hwang/curation/
#     EXP_TPM.tsv
#     cased_sequenced.csv
#
# Output:
#   data/examples/icb_hwang/curation/
#     EXPR.csv (semicolon-delimited)
#
# Usage:
#   Rscript workflow/icb_hwang/scripts/Format_EXPR.R
#
# Optional:
#   Rscript workflow/icb_hwang/scripts/Format_EXPR.R \
#     data/examples/icb_hwang
#
# Purpose:
#   Harmonize RNA expression data for the Hwang cohort
#   following the MAR-40/ICB expression format.
#
# Processing:
#   1. Read the TPM expression matrix.
#   2. Extract gene symbols from Symbol_ID.
#   3. Resolve duplicate genes using the highest total TPM.
#   4. Retain samples with available RNA expression (expr=1).
#   5. Apply log2(TPM + 1).
#   6. Export a gene-by-sample expression matrix.
#
# Notes:
#   - Input values are TPM, not raw read counts.
#   - Data originate from a targeted immune-response panel.
#   - Output sample identifiers are GEO GSM accessions.
#   - Original GEO files remain unchanged.
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

expr_input <- file.path(input_dir, "EXP_TPM.tsv")
case_input <- file.path(input_dir, "cased_sequenced.csv")
expr_output <- file.path(output_dir, "EXPR.csv")

# ------------------------------------------------------------
# 2. Validate input files
# ------------------------------------------------------------

for (f in c(expr_input, case_input)) {
  if (!file.exists(f)) {
    stop("Required input file not found: ", f)
  }
}

# ------------------------------------------------------------
# 3. Read TPM expression matrix
# ------------------------------------------------------------

message("Reading TPM expression matrix...")

expr <- data.table::fread(
  expr_input,
  sep = "\t",
  header = TRUE,
  check.names = FALSE
)

if (!"Symbol_ID" %in% colnames(expr)) {
  stop("Required column 'Symbol_ID' is missing.")
}

sample_columns <- setdiff(colnames(expr), "Symbol_ID")

if (length(sample_columns) == 0) {
  stop("No expression sample columns found.")
}

# Extract gene symbols
# Example: ABCF1_11741283 -> ABCF1

gene_symbols <- sub("_.*$", "", expr$Symbol_ID)

# Convert expression columns to numeric matrix

tpm <- as.matrix(
  expr[, ..sample_columns]
)

storage.mode(tpm) <- "numeric"
rownames(tpm) <- gene_symbols

# ------------------------------------------------------------
# 4. Resolve duplicate gene symbols
# ------------------------------------------------------------

message("Resolving duplicate gene symbols...")

# Retain the row with the highest summed TPM
row_totals <- rowSums(tpm, na.rm = TRUE)

ord <- order(
  rownames(tpm),
  -row_totals
)

tpm <- tpm[ord, , drop = FALSE]

# Keep one row per gene
tpm <- tpm[
  !duplicated(rownames(tpm)),
  ,
  drop = FALSE
]

# Sort genes alphabetically
tpm <- tpm[
  order(rownames(tpm)),
  ,
  drop = FALSE
]

# ------------------------------------------------------------
# 5. Select samples with RNA expression
# ------------------------------------------------------------

message("Reading RNA sample availability...")

case <- read.csv(
  case_input,
  sep = ";",
  header = TRUE,
  stringsAsFactors = FALSE,
  check.names = FALSE
)

required_cols <- c("patient", "expr")

if (!all(required_cols %in% colnames(case))) {
  stop(
    "Missing required columns in cased_sequenced.csv: ",
    paste(
      setdiff(required_cols, colnames(case)),
      collapse = ", "
    )
  )
}

expr_samples <- case$patient[
  !is.na(case$expr) &
    as.character(case$expr) == "1"
]

# Preserve expression matrix sample order
selected_samples <- colnames(tpm)[
  colnames(tpm) %in% expr_samples
]

if (length(selected_samples) == 0) {
  stop("No matching RNA samples found.")
}

tpm <- tpm[
  ,
  selected_samples,
  drop = FALSE
]

message("RNA samples retained: ", ncol(tpm))

# ------------------------------------------------------------
# 6. Log2 transformation
# ------------------------------------------------------------

message("Applying log2(TPM + 1) transformation...")

if (any(!is.finite(tpm) & !is.na(tpm))) {
  stop("Expression matrix contains non-finite values.")
}

if (any(tpm < 0, na.rm = TRUE)) {
  stop("Negative TPM values detected.")
}

tpm <- log2(tpm + 1)

# ------------------------------------------------------------
# 7. Export harmonized expression matrix
# ------------------------------------------------------------

write.table(
  tpm,
  file = expr_output,
  quote = FALSE,
  sep = ";",
  col.names = TRUE,
  row.names = TRUE,
  na = "NA"
)

message("Harmonized expression matrix saved: ", expr_output)
message("Genes: ", nrow(tpm))
message("Samples: ", ncol(tpm))
message("Expression harmonization completed successfully.")
