# MAR-40 Cohort Visualization with Snakemake

**Status:** Implemented and validated with a successful Snakemake dry-run. In the latest execution check, the existing visualization outputs were present and up to date; the R script was not rerun.

## Overview

This workflow generates descriptive figures and summary reports from **already harmonized, sample-level clinical metadata**. It uses R for visualization, Snakemake for workflow orchestration, and Pixi to launch Snakemake. It runs independently of the ICB_Hwang clinical + RNA harmonization workflow.

The workflow does **not** harmonize source data, establish data-access permissions, or confirm that clinical endpoints such as overall survival (OS) and progression-free survival (PFS) are analysis-ready.

## Repository structure

```text
config/
└── visualization.yaml

workflow/
└── visualization/
    ├── Snakefile
    ├── rules.smk
    └── clinical_visualization.R

data/
└── examples/
    └── MAR40_synthetic_sample_level.csv

results/
└── visualization/
    └── <dataset>/

logs/
└── visualization/
    └── <dataset>.log
```

The `results/` and `logs/` directories contain generated outputs and should not be committed to the public repository unless explicitly approved.

## Input requirements

The input is a **comma-delimited CSV** with one row per sample and the required identifiers:

- `cohort`
- `patientid`
- `sampleid`

Additional variables may include cancer type, treatment, sex, age, stage, response, RECIST category, sampling timepoint, OS, PFS, and molecular data availability. Missing values are permitted, including variables unavailable for an entire cohort.

Use the [MAR-40 Data Dictionary](data_dictionary.md) for standardized definitions and accepted values. In particular, distinguish **missing values** from negative observations and distinguish patient-, sample-, treatment-, and timepoint-level information.

**Test input:** `data/examples/MAR40_synthetic_sample_level.csv`. This synthetic dataset enables workflow testing without exposing restricted patient-level records.

## Configuration

Dataset inputs are defined in `config/visualization.yaml`. For example:

```yaml
datasets:
  example:
    input: data/examples/MAR40_synthetic_sample_level.csv
```

To process another approved, harmonized dataset, add a named dataset under `datasets:` with its input CSV path. Each dataset has a separate output directory and log file.

If the visualization rule is configured to use a specific R installation, also set the top-level `rscript` value in `config/visualization.yaml` and ensure `workflow/visualization/rules.smk` reads it. On the tested Windows workstation, R 4.5.2 was available at:

```yaml
rscript: "C:/Program Files/R/R-4.5.2/bin/x64/Rscript.exe"
```

This setting is optional **only if** the rule uses the corresponding `config.get("rscript", "Rscript")` parameter. Otherwise, the rule invokes `Rscript` from the execution environment. Verify the actual rule before relying on this configuration.

## Run from the repository root

In Git Bash:

```bash
# Preview the workflow without running R
pixi run snakemake \
  --snakefile workflow/visualization/Snakefile \
  --cores 1 \
  --dry-run

# Execute the workflow
pixi run snakemake \
  --snakefile workflow/visualization/Snakefile \
  --cores 1 \
  --printshellcmds
```

The R script receives two positional arguments: the **input CSV path** and the **output directory**. The workflow uses the existing `workflow/visualization/clinical_visualization.R`; it does not replace or modify that script.

Before an actual run, confirm the required R packages are installed in the R environment used by the Snakemake rule. The visualization script may require packages such as `ggplot2`, `dplyr`, `tidyr`, and `ComplexHeatmap`.

## Generated outputs

For a dataset named `example`, generated files are written to `results/visualization/example/` and the execution log to `logs/visualization/example.log`.

The workflow declares the following figure outputs:

| Figure | File |
|---|---|
| Cancer type distribution | `01_cancer_donut.png` |
| Treatment distribution | `02_treatment_donut.png` |
| Clinical variable availability | `03_clinical_availability_heatmap.png`, `.pdf` |
| Sex by cohort | `04_sex_by_cohort.png` |
| Sampling timing by cohort | `05_sampling_timing_by_cohort.png` |
| RECIST by cohort | `06_recist_by_cohort.png` |

Additional reports include cohort-level summaries, clinical variable availability and missingness, patient-level conflicts, assay-source labels, observed follow-up summaries, counts underlying figures, and `run_manifest.txt`. The full expected output list is defined in `workflow/visualization/rules.smk`.

These outputs support **descriptive cohort review**; they are not a substitute for source-data QC, endpoint validation, or scientific approval.

## Validation and checks

The reorganized workflow successfully completed a Snakemake dry-run using:

- **Entry point:** `workflow/visualization/Snakefile`
- **Rule file:** `workflow/visualization/rules.smk`
- **R script:** `workflow/visualization/clinical_visualization.R`
- **Example input:** `data/examples/MAR40_synthetic_sample_level.csv`

The subsequent execution command reported **“Nothing to be done (all requested files are present and up to date).”** This confirms Snakemake recognized the existing outputs, but does not constitute a fresh R execution after the directory reorganization.

Before using a new dataset or changing the R script:

1. Confirm the input CSV contains `cohort`, `patientid`, and `sampleid`, and follows the MAR-40 data dictionary.
2. Confirm the selected R executable and required packages are available.
3. Confirm the output filenames produced by `clinical_visualization.R` agree with `FIGURE_FILES` and `REPORT_FILES` in `rules.smk`.
4. Review generated summaries, missingness, and conflict reports for interpretation and potential curation issues.
5. Confirm permissions before sharing any real-data-derived figures, reports, or tables.

Snakemake tracks dependencies and may rerun a dataset when its input file or R script changes. It does not automatically transfer or merge data between institutions.

## Data access and sharing

Restricted clinical datasets must remain in approved institutional storage. Synthetic or otherwise explicitly authorized examples may be shared through the repository. Publication of derived plots or summary tables is also subject to applicable data-use permissions and institutional review.

For upstream curation and standardization procedures, see the [Data Curation SOP](data_curation_SOP.md), [Data Dictionary](data_dictionary.md), and [Quality Control Guide](quality_control.md).
