#!/usr/bin/env Rscript
# ============================================================
# MAR-40 | ICB_Hwang GEO Data Preprocessing (GSE136961)
# ============================================================
# Input:
#   data/examples/icb_hwang/download/
#     GSE136961_series_matrix.txt.gz
#     GSE136961_TPM.tsv.gz
#
# Output:
#   data/examples/icb_hwang/curation/
#     CLIN.txt
#     EXP_TPM.tsv
#
# Usage:
#   Rscript workflow/scripts/icb_hwang/format_downloaded_data.R
#
# Optional:
#   Rscript workflow/scripts/icb_hwang/format_downloaded_data.R \
#     data/examples/icb_hwang
#
# Original source files are never modified.
# ============================================================

suppressPackageStartupMessages({
  library(GEOquery)
  library(data.table)
})

# ------------------------------------------------------------
# 1. Define paths
# ------------------------------------------------------------

args <- commandArgs(trailingOnly = TRUE)

data_root <- if (length(args) >= 1) {
  args[1]
} else {
  "data/examples/icb_hwang"
}

input_dir <- file.path(data_root, "download")
output_dir <- file.path(data_root, "curation")

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

clin_gz <- file.path(input_dir, "GSE136961_series_matrix.txt.gz")
expr_gz <- file.path(input_dir, "GSE136961_TPM.tsv.gz")

clin_output <- file.path(output_dir, "CLIN.txt")
expr_output <- file.path(output_dir, "EXP_TPM.tsv")

# ------------------------------------------------------------
# 2. Validate inputs
# ------------------------------------------------------------

for (f in c(clin_gz, expr_gz)) {
  if (!file.exists(f)) {
    stop("Required input file not found: ", f)
  }
}

# ------------------------------------------------------------
# 3. Extract clinical metadata
# ------------------------------------------------------------

message("Reading GEO clinical metadata...")

# GEOquery can read the decompressed series matrix.
# Use a temporary file to avoid changing original source data.

clin_txt <- tempfile(fileext = "_series_matrix.txt")
on.exit(unlink(clin_txt), add = TRUE)

con_in <- gzfile(clin_gz, "rb")
con_out <- file(clin_txt, "wb")

tryCatch({
  repeat {
    chunk <- readBin(con_in, "raw", n = 1024 * 1024)
    if (length(chunk) == 0) break
    writeBin(chunk, con_out)
  }
}, finally = {
  close(con_in)
  close(con_out)
})

geo <- GEOquery::getGEO(
  filename = clin_txt,
  getGPL = FALSE
)

clin <- Biobase::pData(geo)

colnames(clin) <- gsub("\\W", "_", colnames(clin))

data.table::fwrite(
  clin,
  file = clin_output,
  sep = "\t",
  quote = FALSE,
  na = "NA"
)

message("Clinical metadata saved: ", clin_output)

# ------------------------------------------------------------
# 4. Read expression data
# ------------------------------------------------------------
message("Reading RNA expression matrix...")

# Read compressed TPM directly through an R connection.
# Interpret quotation marks correctly in the TSV file.
# This avoids the Windows/Git Bash decompression path issue.

con <- gzfile(expr_gz, open = "rt")

expr <- tryCatch(
  {
    data.table::as.data.table(
      read.delim(
        con,
        sep = "\t",
        header = TRUE,
        check.names = FALSE,
        stringsAsFactors = FALSE,
        quote = "\"",
        comment.char = ""
      )
    )
  },
  finally = {
    close(con)
  }
)

# Validate expression identifiers
if (!"Symbol_ID" %in% colnames(expr)) {
  stop(
    "Required column 'Symbol_ID' is missing. Found: ",
    paste(head(colnames(expr)), collapse = ", ")
  )
}

message("Expression matrix loaded successfully.")
message("Genes/features: ", nrow(expr))
message("Expression samples: ", ncol(expr) - 1L)

# ------------------------------------------------------------
# 5. Match expression samples to GEO accessions
# ------------------------------------------------------------

if (!"Symbol_ID" %in% colnames(expr)) {
  stop("Required Symbol_ID column is missing.")
}

if (!all(c("title", "geo_accession") %in% colnames(clin))) {
  stop("Required GEO sample metadata columns are missing.")
}

sample_columns <- setdiff(colnames(expr), "Symbol_ID")

match_index <- match(sample_columns, clin$title)

if (anyNA(match_index)) {
  stop(
    "Unmatched expression sample titles: ",
    paste(sample_columns[is.na(match_index)], collapse = ", ")
  )
}

geo_ids <- clin$geo_accession[match_index]

if (anyDuplicated(geo_ids)) {
  stop("Duplicate GEO accessions found during expression mapping.")
}

data.table::setnames(
  expr,
  old = sample_columns,
  new = geo_ids
)

# ------------------------------------------------------------
# 6. Export expression matrix
# ------------------------------------------------------------

data.table::fwrite(
  expr,
  file = expr_output,
  sep = "\t",
  quote = FALSE,
  na = "NA"
)

message("Expression matrix saved: ", expr_output)
message("Genes/features: ", nrow(expr))
message("Expression samples: ", length(geo_ids))
message("Preprocessing completed successfully.")
