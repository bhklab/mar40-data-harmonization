# Example 1 — ICB_Hwang (Clinical + RNA)

**Status:** Implemented and successfully executed locally using Pixi, Snakemake, and R. Automated quality control is planned.

## Overview

The Hwang immunotherapy cohort is available through GEO accession **GSE136961**. This example demonstrates a reproducible workflow for harmonizing clinical metadata and targeted RNA expression data and integrating them into an expression-only MultiAssayExperiment (MAE).

The workflow uses GEO clinical metadata, TPM-normalized gene expression, cohort-specific clinical harmonization functions, and GENCODE v19 gene annotations. It does **not** generate DNA assay data.

| Component | Validated local result |
|---|---:|
| Clinical records | 21 |
| RNA expression samples | 21 |
| Original expression features | 393 |
| Harmonized expression genes | 390 |
| Genes matched to GENCODE v19 | 381 |
| Unmatched genes | 9 |
| Annotated genes | 381 |
| MAE sample mappings | 21 |
| Expression transformation | `log2(TPM + 1)` |
| Gene annotation | GENCODE v19 |

The expression data originate from an **Oncomine Immune Response Research Assay** targeted immune-response panel, not whole-transcriptome RNA sequencing.

## Source and attribution

- **Original repository:** [RibaA/ICB_Hwang](https://github.com/RibaA/ICB_Hwang)
- **GEO dataset:** [GSE136961](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE136961)
- **MAR-40 R scripts:** `workflow/icb_hwang/scripts/`
- **Snakemake entry point:** `workflow/icb_hwang/Snakefile`
- **Rule definitions:** `workflow/icb_hwang/rules.smk`
- **Configuration:** `config/icb_hwang.yaml`

The MAR-40 implementation adapts the original Hwang processing scripts to this repository's paths and Snakemake orchestration, while preserving cohort-specific processing conventions where applicable.

## Repository structure

```text
config/
└── icb_hwang.yaml

workflow/
└── icb_hwang/
    ├── Snakefile
    ├── rules.smk
    └── scripts/
        ├── format_downloaded_data.R
        ├── Format_CLIN.R
        ├── Format_cased_sequenced.R
        ├── Format_EXPR.R
        └── create_MAE.R

data/
└── examples/
    └── icb_hwang/
        ├── README.md
        ├── download/
        ├── annot/
        └── curation/
```

The Hwang workflow has a dedicated Snakefile and runs independently of the clinical visualization workflow.

## Required local input data

Place the following files under `data/examples/icb_hwang/` before running the workflow.

| Directory | Required file | Purpose |
|---|---|---|
| `download/` | `GSE136961_series_matrix.txt.gz` | GEO sample and clinical metadata |
| `download/` | `GSE136961_TPM.tsv.gz` | TPM-normalized targeted expression |
| `annot/` | `curation_tissue.csv` | Tissue harmonization |
| `annot/` | `Gencode.v19.annotation.RData` | Gene annotations (`features_gene`) |

Other provenance files, such as `curation_drug.csv` and `DATASET_LOAD_INFO.csv`, may be retained locally in `annot/`; they are not declared as required inputs in the current five-rule pipeline.

The current Snakemake workflow **expects these input files locally**; it does not download them automatically. Local downloads, annotation binaries, and generated curation files are excluded from Git unless separately approved for redistribution.

## Processing workflow

The workflow consists of five R scripts, with execution and dependencies managed by Snakemake.

| Step | R script | Output under `curation/` |
|---|---|---|
| 1. GEO preprocessing | `format_downloaded_data.R` | `CLIN.txt`, `EXP_TPM.tsv` |
| 2. Clinical harmonization | `Format_CLIN.R` | `CLIN.csv` |
| 3. Molecular availability | `Format_cased_sequenced.R` | `cased_sequenced.csv` |
| 4. RNA harmonization | `Format_EXPR.R` | `EXPR.csv` |
| 5. MAE construction | `create_MAE.R` | `ICB_Hwang.rds` |

### GEO preprocessing and sample mapping

`format_downloaded_data.R` extracts sample metadata from the GEO series matrix and reads the compressed TPM data through an R gzip connection. Expression columns identified by sample titles (for example, `D01`, `D06`, and `N10`) are matched against `clin$title` and renamed using the corresponding `clin$geo_accession` values (`GSM...`). Original downloaded files remain unchanged.

### Clinical harmonization

`Format_CLIN.R` preserves the original GEO metadata fields and creates legacy ICB clinical variables, including tissue classification, treatment class, survival times, event indicators, and derived response annotations. Survival times are converted from days to months.

The cohort included **nivolumab or pembrolizumab** (anti-PD-1); the study-level treatment options should not be interpreted as verified patient-specific combined therapy. `Get_Response()` may derive response using PFS-related information rather than directly reproducing the source study's RECIST-based durable clinical benefit classification. These definitions require scientific review for cross-cohort analyses.

### Molecular availability

`Format_cased_sequenced.R` creates the legacy ICB fields `patient`, `snv`, `cna`, and `expr`. RNA availability is checked against expression sample columns. SNV/CNA data not supplied in this curated example should not be interpreted as biological absence of alterations.

### RNA expression harmonization

`Format_EXPR.R` extracts gene symbols from `Symbol_ID`, resolves duplicate symbols by retaining the row with the highest total TPM across samples, and keeps RNA-available samples. Values are transformed using **`log2(TPM + 1)`**. The output matrix has genes as rows and GEO GSM sample identifiers as columns.

### MultiAssayExperiment construction

`create_MAE.R` joins harmonized clinical and expression samples by matching identifiers, annotates genes using GENCODE v19, and constructs an expression-only MAE with a ranged SummarizedExperiment. Genes without matching annotation are omitted from the annotated MAE but remain in `EXPR.csv`.

## Software dependencies

- **Pixi:** Launches the workflow tooling.
- **Snakemake:** Schedules and connects the five processing rules.
- **R:** Performs scientific data processing and constructs the MAE.

The successfully tested local installation used **R 4.5.2 on Windows**. The R dependencies checked successfully were `GEOquery`, `Biobase`, `data.table`, `stringr`, `tibble`, `SummarizedExperiment`, `MultiAssayExperiment`, `GenomicRanges`, and `S4Vectors`.

`Format_CLIN.R` currently loads shared functions from **ICB_Common** on GitHub using `source()`. This requires internet access at execution time and does not yet pin those remote functions to a specific commit. The Pixi environment should not be assumed to manage the separately installed Windows R packages unless explicitly configured to do so.

The R executable is configured through `config/icb_hwang.yaml`. The workflow was successfully tested using R 4.5.2 on Windows (`C:/Program Files/R/R-4.5.2/bin/x64/Rscript.exe`). Users should update this path for their local installation.

## Run from the repository root

Commands below use Git Bash syntax:

```bash
# Inspect registered rules
pixi run snakemake \
  --snakefile workflow/icb_hwang/Snakefile \
  --list-rules

# Preview dependencies; does not run R
pixi run snakemake \
  --snakefile workflow/icb_hwang/Snakefile \
  --cores 1 \
  --dry-run

# Execute the Hwang workflow
pixi run snakemake \
  --snakefile workflow/icb_hwang/Snakefile \
  --cores 1 \
  --printshellcmds
```

In PowerShell, run each command on one line or use PowerShell's backtick continuation instead of `\`.

The final object is saved to:

`data/examples/icb_hwang/curation/ICB_Hwang.rds`

## Validated local execution

In the successful local run, **393 original expression features** were reduced to **390 harmonized genes**; **381 genes matched GENCODE v19** and **9 were unmatched**. The final MAE contained **381 annotated gene rows and 21 expression columns**. The MAE contained **21 clinical records** and its `sampleMap` had **21 mappings**, with matching GEO GSM identifiers for `primary` and assay `colname`.

These are observed local results showing successful processing and technical clinical–RNA sample integration. They do **not** establish that every clinical harmonization field has undergone full scientific validation.

For manual inspection in R:

```r
library(MultiAssayExperiment)
mae <- readRDS("data/examples/icb_hwang/curation/ICB_Hwang.rds")
dim(mae[["expr"]])
nrow(colData(mae))
sampleMap(mae)
```

## Quality control and planned improvements

**Automated QC is deferred.** Initial manual inspection confirmed that expression samples and clinical records were present and linked in the MAE. Planned additions include automated sample correspondence checks, missingness and identifier validation, response/survival definition review, gene mapping summaries, source checksums, pinned ICB_Common functions, and cross-platform environment testing.

## MAR-40 data dictionary considerations

This example retains some **legacy ICB** field definitions for compatibility with the original workflow. In particular, the meanings of `rna` and `rna_info` and the use of GSM accession as the legacy `patient` key differ from the MAR-40 core metadata specification. Future use in standardized MAR-40 visualizations or cross-cohort analyses should employ a documented mapping or adapter rather than silently changing the cohort-specific source fields.

## Data sharing

Only scripts, configurations, documentation, and approved example resources should be committed to Git. Original downloaded inputs, large annotations, generated harmonized matrices, and MAE objects should remain local unless their sharing is explicitly reviewed and permitted. The documentation alone does not provide all source files or make the workflow completely self-contained.
