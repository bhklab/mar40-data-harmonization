# MAR-40 synthetic visualization example

This folder contains **synthetic, shareable sample-level clinical metadata** for demonstrating the MAR-40 cohort visualization workflow. It is **not** real patient data, a processed molecular assay matrix, or a source clinical file. The values are illustrative, not biological evidence.

## Dataset

`MAR40_synthetic_sample_level.csv`: 850 sample records from 10 simulated cohorts. It includes `cohort`, `patientid`, `sampleid`, cancer type, treatment, sex, RECIST, binary response, OS/PFS metadata, assay availability, sample timing, and `access type`. Some values are missing intentionally. It uses `F`/`M` for sex and `R`/`NR` for binary response. A missing response is distinct from `NR`; likewise unknown assay availability is not `No`. The plot script also accepts `access_type` as a header.

The access categories in this file are *simulation labels*, not permissions to distribute real cohort data. This example does not provide separate RNA expression or DNA alteration matrices.

## Run (from repository root)

```bash
Rscript scripts/MAR40_cohort_visualization.R
```

The default input is `data/examples/MAR40_synthetic_sample_level.csv`. Generated files are written to `results/visualization/example/`, which can remain excluded from Git. Pass alternative paths for approved local data:

```bash
Rscript scripts/MAR40_cohort_visualization.R /approved/path/harmonized_sample_level.csv /approved/path/output/figures
```

Input data must already be harmonized according to `docs/data_dictionary.md` and `docs/data_curation_SOP.md`. Real confidential or controlled-access patient-level data should never be committed to a public repository. Data with all-missing fields (such as `stage`) or partially missing `response` values are allowed; the script exports missingness reports and reports patient-level conflicts.

## Repository tracking

Keep this synthetic example tracked under `data/examples/`; retain real raw and processed datasets only on approved storage. If a parent `.gitignore` ignores `data/` entirely, add suitable negation patterns to unignore this subdirectory and its files.
