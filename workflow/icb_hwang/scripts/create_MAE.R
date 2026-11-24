#!/usr/bin/env Rscript
# ============================================================
# MAR-40 | ICB_Hwang MultiAssayExperiment Creation (GSE136961)
# ============================================================
# Inputs:
#   data/examples/icb_hwang/curation/
#     CLIN.csv
#     EXPR.csv
#     cased_sequenced.csv
#
#   data/examples/icb_hwang/annot/
#     Gencode.v19.annotation.RData
#
# Output:
#   data/examples/icb_hwang/curation/
#     ICB_Hwang.rds
#
# Usage:
#   Rscript workflow/icb_hwang/scripts/create_MAE.R
#
# Optional:
#   Rscript workflow/icb_hwang/scripts/create_MAE.R \
#     data/examples/icb_hwang
#
# Purpose:
#   Construct an expression-only MultiAssayExperiment for
#   the Hwang cohort using GENCODE v19 annotations.
#
# Processing:
#   1. Load harmonized clinical and RNA data.
#   2. Match GEO sample identifiers across input files.
#   3. Annotate gene symbols using GENCODE v19.
#   4. Construct a ranged SummarizedExperiment.
#   5. Integrate expression and clinical data into an MAE.
#   6. Export the final RDS object.
#
# Notes:
#   - RNA expression values are already log2(TPM + 1).
#   - Expression transformation is not repeated here.
#   - Genes without matching GENCODE v19 symbols are excluded
#     from the MAE but remain available in EXPR.csv.
#   - GEO clinical metadata fields are preserved.
#   - Original downloaded GEO files remain unchanged.
# ============================================================

suppressPackageStartupMessages({
  library(SummarizedExperiment)
  library(MultiAssayExperiment)
  library(GenomicRanges)
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
annot_dir <- file.path(data_root, "annot")
output_dir <- file.path(data_root, "curation")

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

clin_input <- file.path(input_dir, "CLIN.csv")
expr_input <- file.path(input_dir, "EXPR.csv")
case_input <- file.path(input_dir, "cased_sequenced.csv")

annot_input <- file.path(
  annot_dir,
  "Gencode.v19.annotation.RData"
)

mae_output <- file.path(
  output_dir,
  "ICB_Hwang.rds"
)

# ------------------------------------------------------------
# 2. Validate input files
# ------------------------------------------------------------

for (f in c(clin_input, expr_input, case_input, annot_input)) {
  if (!file.exists(f)) {
    stop("Required input file not found: ", f)
  }
}

# ------------------------------------------------------------
# 3. Load GENCODE v19 annotations
# ------------------------------------------------------------

message("Loading GENCODE v19 annotation...")

annot_env <- new.env(parent = emptyenv())
load(annot_input, envir = annot_env)

if (!exists("features_gene", envir = annot_env, inherits = FALSE)) {
  stop("Annotation file does not contain 'features_gene'.")
}

features_gene <- get("features_gene", envir = annot_env)

required_annot_cols <- c(
  "gene_name", "gene_id", "seqnames", "start", "end", "strand"
)

if (!all(required_annot_cols %in% colnames(features_gene))) {
  stop(
    "Missing required annotation columns: ",
    paste(
      setdiff(required_annot_cols, colnames(features_gene)),
      collapse = ", "
    )
  )
}

# ------------------------------------------------------------
# 4. Load harmonized clinical and RNA data
# ------------------------------------------------------------

message("Reading harmonized clinical metadata...")

clin <- read.csv(
  clin_input,
  sep = ";",
  stringsAsFactors = FALSE,
  check.names = FALSE
)

case <- read.csv(
  case_input,
  sep = ";",
  stringsAsFactors = FALSE,
  check.names = FALSE
)

message("Reading harmonized expression matrix...")

expr <- read.csv(
  expr_input,
  sep = ";",
  row.names = 1,
  check.names = FALSE
)

# ------------------------------------------------------------
# 5. Validate clinical and molecular identifiers
# ------------------------------------------------------------

if (!"patient" %in% colnames(clin)) {
  stop("Required column 'patient' is missing from CLIN.csv.")
}

if (!all(c("patient", "expr") %in% colnames(case))) {
  stop(
    "Required columns 'patient' and/or 'expr' ",
    "are missing from cased_sequenced.csv."
  )
}

if (anyNA(clin$patient) ||
    anyDuplicated(clin$patient) ||
    any(!nzchar(trimws(clin$patient)))) {
  stop("Clinical sample identifiers must be unique and nonmissing.")
}

if (anyNA(case$patient) || anyDuplicated(case$patient)) {
  stop("Availability table has missing or duplicate sample IDs.")
}

if (anyDuplicated(colnames(expr))) {
  stop("Expression matrix contains duplicate sample IDs.")
}

rownames(clin) <- clin$patient

# ------------------------------------------------------------
# 6. Match clinical and RNA samples
# ------------------------------------------------------------

message("Matching clinical and RNA samples...")

expr_samples <- as.character(
  case$patient[!is.na(case$expr) &
                 as.character(case$expr) == "1"]
)

# Preserve the original expression sample order
samples <- colnames(expr)[
  colnames(expr) %in% expr_samples &
    colnames(expr) %in% rownames(clin)
]

if (length(samples) == 0) {
  stop("No matching clinical and RNA samples found.")
}

unmatched_expr <- setdiff(expr_samples, samples)

if (length(unmatched_expr) > 0) {
  stop(
    "Samples flagged as RNA-available are missing from ",
    "clinical metadata or expression matrix: ",
    paste(unmatched_expr, collapse = ", ")
  )
}

expr <- as.matrix(expr[, samples, drop = FALSE])
storage.mode(expr) <- "numeric"

clin <- clin[samples, , drop = FALSE]

if (!identical(colnames(expr), rownames(clin))) {
  stop("Clinical and expression sample orders do not match.")
}

message("Matched samples: ", length(samples))

# ------------------------------------------------------------
# 7. Match gene symbols to GENCODE v19
# ------------------------------------------------------------

message("Mapping gene symbols to GENCODE v19...")

if (anyNA(rownames(expr)) || anyDuplicated(rownames(expr))) {
  stop("Expression gene symbols must be unique and nonmissing.")
}

# Retain the first annotation match for each gene symbol,
# consistent with the original Hwang implementation.

feature_idx <- match(
  rownames(expr),
  features_gene$gene_name
)

keep <- !is.na(feature_idx)

if (!any(keep)) {
  stop("No expression genes matched GENCODE v19.")
}

message("Input genes: ", nrow(expr))
message("Matched genes: ", sum(keep))
message("Unmatched genes: ", sum(!keep))

expr <- expr[keep, , drop = FALSE]

feature_rows <- features_gene[
  feature_idx[keep],
  ,
  drop = FALSE
]

gene_ids <- as.character(feature_rows$gene_id)

if (anyNA(gene_ids) || anyDuplicated(gene_ids)) {
  stop(
    "GENCODE mapping produced missing or duplicate gene IDs. ",
    "Review ambiguous gene-symbol mappings."
  )
}

rownames(expr) <- gene_ids

# ------------------------------------------------------------
# 8. Construct genomic ranges
# ------------------------------------------------------------

message("Creating GENCODE genomic ranges...")

ranges <- GenomicRanges::makeGRangesFromDataFrame(
  feature_rows,
  keep.extra.columns = TRUE,
  seqnames.field = "seqnames",
  start.field = "start",
  end.field = "end",
  strand.field = "strand"
)

names(ranges) <- gene_ids

if (length(ranges) != nrow(expr)) {
  stop("Gene annotation and expression dimensions do not match.")
}

# ------------------------------------------------------------
# 9. Standardize clinical column names
# ------------------------------------------------------------

message("Standardizing clinical column names...")

renamed_cols <- c(
  drug_type = "treatment",
  primary = "cancer_type",
  t.pfs = "survival_time_pfs",
  pfs = "event_occurred_pfs",
  t.os = "survival_time_os",
  os = "event_occurred_os",
  patient = "patientid"
)

for (old in names(renamed_cols)) {
  new <- renamed_cols[[old]]

  if (old %in% colnames(clin)) {
    if (new %in% colnames(clin) && new != old) {
      stop("Cannot rename ", old, ": ", new, " already exists.")
    }

    colnames(clin)[colnames(clin) == old] <- new
  }
}

if (!"patientid" %in% colnames(clin)) {
  stop("Required patientid column is missing after renaming.")
}

# ------------------------------------------------------------
# 10. Construct SummarizedExperiment
# ------------------------------------------------------------

message("Constructing SummarizedExperiment...")

se <- SummarizedExperiment::SummarizedExperiment(
  assays = list(expr = expr),
  rowRanges = ranges,
  colData = S4Vectors::DataFrame(clin)
)

# ------------------------------------------------------------
# 11. Construct MultiAssayExperiment
# ------------------------------------------------------------

message("Constructing MultiAssayExperiment...")

mae <- MultiAssayExperiment::MultiAssayExperiment(
  experiments = list(expr = se),
  colData = S4Vectors::DataFrame(clin)
)

# ------------------------------------------------------------
# 12. Validate and export MAE
# ------------------------------------------------------------

if (nrow(mae[["expr"]]) != nrow(expr) ||
    ncol(mae[["expr"]]) != ncol(expr)) {
  stop("Final MAE expression dimensions do not match.")
}

saveRDS(mae, mae_output)

message("MAE saved: ", mae_output)
message("Annotated genes: ", nrow(expr))
message("Samples: ", ncol(expr))
message("MAE creation completed successfully.")