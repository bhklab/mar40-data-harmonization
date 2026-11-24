# Example 1 — ICB_Hwang (Clinical + RNA)

**Status:** Merge overlay prepared; R scripts must be imported and the merged workflow validated locally before claiming reproducibility.

The Hwang immunotherapy cohort is associated with GEO **GSE136961**. The workflow uses source clinical data, a targeted RNA expression matrix, documented cohort-specific standardization, and GENCODE v19 gene annotations to create an expression-only MultiAssayExperiment (MAE). It does not create DNA assay data.

## Source and attribution

- Source repository: <https://github.com/RibaA/ICB_Hwang>
- GEO: <https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE136961>
- Imported R source revision: `workflow/scripts/icb_hwang/UPSTREAM_COMMIT.txt` (generated on import)
- Upstream scripts are copied into `workflow/scripts/icb_hwang/` without moving any repository data, binary annotation files, or Git metadata.

## Import existing scripts

From the **MAR-40 root directory**, with Git Bash:

```bash
git clone https://github.com/RibaA/ICB_Hwang.git ../ICB_Hwang
pixi run python tools/import_icb_hwang.py --source ../ICB_Hwang
```

Alternatively, `pixi run python tools/import_icb_hwang.py --clone` downloads the repository automatically. Existing imported files will not be overwritten unless `--overwrite` is used.

The importer updates only the stale comment in `Format_EXPR.R` from `log2(TPM + 0.001)` to **`log2(TPM + 1)`**; the computational expression transformation in the upstream script already uses `log2(tpm + 1)`.

## Connect workflow

Append this line to the **existing** `workflow/Snakefile` without removing its visualization rules or changing the default `all` target:

```python
include: "rules/icb_hwang.smk"
```

The Hwang rules have unique `hwang_` prefixes. Use the explicit Hwang MAE target below so the original visualization workflow remains independent.

## Required local annotation and dependencies

- Place the approved `Gencode.v19.annotation.RData` containing `features_gene` at `resources/annotations/Gencode.v19.annotation.RData`, or update `config/icb_hwang.yaml` to use the approved existing path.
- The tissue annotation `curation_tissue.csv` is downloaded by the workflow.
- R packages include `GEOquery`, `data.table`, `stringr`, `tibble`, `SummarizedExperiment`, `MultiAssayExperiment`, `GenomicRanges`, and their dependencies.
- `Format_CLIN.R` currently loads three `ICB_Common` helpers from upstream `raw.githubusercontent.com` using `source()`. This requires network access unless these functions are separately vendored and the script adapted.
- Install and test these R/Bioconductor dependencies in your selected environment. The overlay **does not edit** `pixi.toml` or `pixi.lock`, because the existing platform/environment configuration has not been supplied.
- For Windows, execution in Linux/WSL may be more reliable than native Git Bash. All paths are configured relative to the MAR-40 repository.

## Dry run and execution

```bash
# Preview required jobs; an existing annotation file is necessary for MAE execution
pixi run snakemake --snakefile workflow/Snakefile --cores 1 \
  --dry-run data/procdata/icb_hwang/ICB_Hwang.rds

# Run the Hwang curation example
pixi run snakemake --snakefile workflow/Snakefile --cores 1 \
  data/procdata/icb_hwang/ICB_Hwang.rds
```

**Expected outputs** are `data/procdata/icb_hwang/CLIN.csv`, `EXPR.csv`, `cased_sequenced.csv`, and `ICB_Hwang.rds`. Source GEO downloads are stored in `data/rawdata/icb_hwang/download/`. These are generated data and should not be committed indiscriminately to a public repository.

## Scientific validation prior to release

Confirm the GEO download checksums and sample IDs; verify clinical mapping, missingness, RECIST/response and survival definitions; confirm that TPM values are transformed using `log2(TPM + 1)`; check expression sample linkage and the MAE `sampleMap`; verify GENCODE v19 feature mappings and record unmatched genes. Compare counts against the upstream run, but do not assume the published figures are reproduced until local outputs have been checked.

**Important:** The upstream `Format_CLIN.R` includes cohort-specific clinical response logic and sources remote helper functions. It should undergo scientific review rather than being described as universally validated MAR-40 response harmonization. Also, its `rna` and `rna_info` semantics differ from the MAR-40 core availability field specification; consider a documented adapter for downstream standardized visualizations rather than silently changing the upstream file.
