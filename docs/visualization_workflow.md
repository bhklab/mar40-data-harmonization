# MAR-40 cohort visualization with Snakemake

## Scope and inputs

Run from the repository root. The workflow invokes the **existing** `workflow/scripts/clinical_visualization.R` and expects an already harmonized, comma-delimited, sample-level table containing `cohort`, `patientid`, and `sampleid`. The script accepts input and output paths as its first two positional arguments. The synthetic example lives at `data/examples/MAR40_synthetic_sample_level.csv` and is suitable for testing; restricted clinical data must remain in approved institutional storage.

Missing fields (e.g. all-missing `age` or `stage`, partially missing `response`) are permitted. Interpret `F/M`, `R/NR`, `CR/PR/SD/PD/NE`, and `NA` using the MAR-40 data dictionary. This workflow **does not** perform source-specific harmonization, determine data-access rights, or verify that OS/PFS are analysis-ready.

## Files

- `workflow/Snakefile`: workflow entry point
- `workflow/rules/visualization.smk`: rule and expected outputs
- `workflow/scripts/clinical_visualization.R`: existing R visualization script (not overwritten by this bundle)
- `config/visualization.yaml`: datasets and input paths
- `data/examples/MAR40_synthetic_sample_level.csv`: tracked synthetic example
- `results/visualization/<dataset>/`: generated figures, QC tables, and manifest
- `logs/visualization/<dataset>.log`: execution log

## Run

```bash
snakemake --snakefile workflow/Snakefile --cores 1 --dry-run
snakemake --snakefile workflow/Snakefile --cores 1
```

If Snakemake is installed in Pixi, use `pixi run snakemake --snakefile workflow/Snakefile --cores 1` instead. The environment must also provide `Rscript` and the R dependencies `ggplot2`, `dplyr`, `tidyr`, and `ComplexHeatmap` to the shell; validate package availability using `Rscript -e 'sapply(c("ggplot2","dplyr","tidyr","ComplexHeatmap"), requireNamespace, quietly=TRUE)'`. Pixi tasks and package definitions have not been verified against your local `pixi.toml`.

To run a different harmonized CSV, add a dataset under `datasets:` in `config/visualization.yaml` (or provide a separate local config via `--configfile`). Each dataset writes to its own results subfolder.

### Example

```yaml
datasets:
  example:
    input: data/examples/MAR40_synthetic_sample_level.csv
  ucl:
    input: /approved/institutional/storage/UCL_harmonized_samples.csv
```

## Before the first run

1. Confirm `workflow/scripts/clinical_visualization.R` exists and accepts `INPUT.csv OUTPUT_DIR`. If not, adapt the script or the rule.
2. Confirm its output filenames match `FIGURE_FILES` and `REPORT_FILES` in `workflow/rules/visualization.smk`. The list is based on the previously reviewed v1.1 script; if filenames differ, update the rule.
3. Verify the source CSV is standardized. The R script does not automatically import semicolon-delimited source metadata.
4. Check `.gitignore` excludes `/results/` and `/logs/` (and non-shareable `/data/rawdata/`, `/data/procdata/`) but does not exclude `/data/examples/`.
5. Only publish input CSVs, figures, and reports when their sharing permissions allow it.

Snakemake is incremental: edit the input CSV or the R script to rerun the corresponding dataset. No cross-site dataset is automatically transferred or merged.
