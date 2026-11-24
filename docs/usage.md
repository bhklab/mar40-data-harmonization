# MAR-40 Usage Guide

**Version:** 1.0   
**Scope:** Participating MAR-40 collaborators at UHN, UCL, and McGill University

## 1. Purpose

This guide explains how collaborators can run the implemented MAR-40 clinical cohort visualization workflow and describes the planned clinical and molecular harmonization examples. It complements the [Data Curation SOP](data_curation_SOP.md), [Data Dictionary](data_dictionary.md), [Quality Control Framework](quality_control.md), and [Data Sources Guide](data_sources.md).

The repository uses **Pixi** for environment management and **Snakemake** for the implemented cohort visualization workflow. The proposed clinical/RNA/DNA harmonization pipelines remain separate from this working example and are not yet executable.

The workflow must be executable inside each site's approved computing environment. The presence of code or documentation does not authorize the movement of controlled-access or private data between institutions.

## 2. Two reference examples

Two additional **planned** example cohorts will demonstrate different assay configurations. Neither clinical/molecular harmonization example should be presented as implemented yet. The existing synthetic sample-level dataset is for the **implemented descriptive visualization workflow**.

| Example | Available inputs | Intended outputs |
| --- | --- | --- |
| **Example 1: Clinical + RNA** | Clinical metadata, RNA expression, patient-to-sample mapping | Harmonized clinical metadata and RNA matrix, QC reports, provenance, optional RNA MAE |
| **Example 2: Clinical + RNA + DNA** | Clinical metadata, RNA expression, DNA alteration data, patient-to-sample mapping | Harmonized clinical metadata, RNA and DNA data, QC reports, provenance, optional multi-assay MAE |

Examples should contain **synthetic data or data explicitly authorized for public redistribution**. They should illustrate realistic source-specific variable names, missing values, and repeated patient samples. They must not contain direct patient identifiers.

**Assay availability is explicit:** Example 1 does not require or generate DNA files. DNA processing is enabled only for cohorts where DNA inputs are declared.

## 3. Prerequisites and environment

- Git, to obtain the repository and track code versions.
- [Pixi](https://pixi.sh/latest/), to install the locked project environment.
- Snakemake, R, Python, and Bioconductor dependencies **as declared by the project's environment configuration**.
- Read/write permissions for the selected local input and output locations.

From a terminal, clone the repository (or use an existing checkout):

```bash
git clone https://github.com/bhklab/mar40-data-harmonization.git
cd mar40-data-harmonization
pixi install
```

`pixi install` assumes the checkout includes a valid Pixi manifest. Do not install additional untracked package versions as a substitute for the agreed project environment; document any site-specific changes.

## 4. Input data contract

For the **implemented visualization workflow**, the input is a previously harmonized sample-level CSV with required identifiers `cohort`, `patientid`, and `sampleid`. Configure its path in `config/visualization.yaml`. For the **planned molecular examples**, provide cohort-specific configurations identifying available clinical and assay inputs. The latter paths below are illustrative and are not assertions that those files exist.

```text
data/
├── examples/
│   └── MAR40_synthetic_sample_level.csv  # Existing visualization example
├── rawdata/
│   └── examples/                          # Proposed, not yet implemented
│       ├── example_clinical_rna/
│       │   ├── clinical.csv
│       │   ├── rna_expression.tsv
│       │   └── sample_map.csv
│       └── example_clinical_rna_dna/
│           ├── clinical.csv
│           ├── rna_expression.tsv
│           ├── dna_alterations.tsv
│           └── sample_map.csv
└── procdata/

results/
└── visualization/
    └── example/                            # Generated outputs
```

### 4.1 Clinical metadata

The source file should contain a documented patient identifier, and any additional fields available for cancer type, histology, stage, age, sex, treatment, response, survival, and sampling timepoints. The source file **does not need to use standardized column names**: mappings to the MAR-40 target variables must be documented according to the [Data Dictionary](data_dictionary.md).

- Treat `(cohort, patientid)` as the unique patient key for cohort-level summaries unless a validated cross-cohort linkage exists.
- Preserve original source values in the approved environment; do not silently replace unrecognized codes.
- Document survival units, time origin, and event/censoring conventions before transformation.
- Missing optional clinical data are reported as missing, not treated as negative observations.

### 4.2 RNA expression

Document whether the input is counts, TPM, another normalized expression scale, or microarray data. Capture the platform, gene identifier system, genome build when relevant, normalization method, transformation, reference annotation release, and sample identifiers.

MAR-40 generally uses **GENCODE v19 for applicable published/processed datasets** and **GENCODE v40 for standardized reprocessing when raw data are available**; when a publication or source supplies a specific annotation release, retain that documented information. Do **not** assume a dataset used GENCODE v19 solely because it is published or its annotation is unknown. Any gene-ID or genome-build conversion must be traceable.

### 4.3 DNA alterations (Example 2 only)

Document the actual assay and input representation (for example, SNV/indel calls, CNA segments, or a curated alteration matrix). Capture the genome build, variant annotation and filtering methods, sample IDs, and rules used to produce a gene-by-sample representation. **Do not assume all DNA datasets contain both SNV and CNA data.**

### 4.4 Patient-to-sample linkage

A sample mapping file or equivalent verified linkage must associate each assay sample with its clinical patient. Multiple samples per patient and different sample availability across assays are permitted, but ambiguous or unmatched IDs must be reported by QC.

## 5. Cohort-specific configuration

The implemented visualization workflow uses `config/visualization.yaml`, with a `datasets:` configuration for harmonized sample-level CSV inputs. The following `cohorts:` YAML is **only a proposal for the future clinical/RNA/DNA workflows**; it is not compatible with the current visualization rules:

```yaml
cohorts:
  example_clinical_rna:
    clinical: data/rawdata/examples/example_clinical_rna/clinical.csv
    sample_map: data/rawdata/examples/example_clinical_rna/sample_map.csv
    rna:
      enabled: true
      file: data/rawdata/examples/example_clinical_rna/rna_expression.tsv
      units: source_documented
      annotation: source_documented
    dna:
      enabled: false

  example_clinical_rna_dna:
    clinical: data/rawdata/examples/example_clinical_rna_dna/clinical.csv
    sample_map: data/rawdata/examples/example_clinical_rna_dna/sample_map.csv
    rna:
      enabled: true
      file: data/rawdata/examples/example_clinical_rna_dna/rna_expression.tsv
      units: source_documented
      annotation: source_documented
    dna:
      enabled: true
      file: data/rawdata/examples/example_clinical_rna_dna/dna_alterations.tsv
      representation: source_documented
      genome_build: source_documented
```

The final schema, mapping-file paths, and workflow target names must match the implemented `Snakefile` and shared config before execution.

## 6. Workflow stages

For either example, the intended sequence is:

1. **Register inputs:** record cohort, provenance, access classification, source version, available assays, and input checksums where permitted.
2. **Harmonize clinical data:** apply versioned source-to-target mappings, controlled values, and unit conversions.
3. **Prepare molecular assays:** validate identifiers and measurement scales; process RNA and, only where declared, DNA.
4. **Validate linkages:** check clinical IDs, assay sample IDs, and patient-to-sample relationships.
5. **Integrate data:** construct appropriate harmonized tables and, where supported, a `MultiAssayExperiment` (MAE).
6. **Run QC:** generate missingness, mapping, consistency, assay, and integration checks.
7. **Record provenance:** capture input versions, code commit, environment, rule versions, exceptions, and output locations.

**QC checks should flag uncertain mappings rather than silently dropping records.** Final release or permitted sharing follows the access conditions and review process defined in the SOP.

## 7. Running Snakemake

### 7.1 Implemented clinical visualization workflow

The working Snakemake workflow creates descriptive cohort figures and summary/QC-support reports from standardized sample-level clinical metadata. It does **not** harmonize source clinical data or process RNA/DNA files.

| Component | Current path |
| --- | --- |
| Example input | `data/examples/MAR40_synthetic_sample_level.csv` |
| Configuration | `config/visualization.yaml` |
| Workflow entry point | `workflow/visualization/Snakefile` |
| Snakemake rule | `workflow/visualization/rules.smk` |
| Analysis script | `workflow/visualization/clinical_visualization.R` |
| Output directory | `results/visualization/example/` |
| Execution log | `logs/visualization/example.log` |

Run the following from the **repository root** after `pixi install`:

```bash
# Check planned jobs without executing them
pixi run snakemake --snakefile workflow/visualization/Snakefile --cores 1 --dry-run

# Execute the visualization
pixi run snakemake --snakefile workflow/visualization/Snakefile --cores 1

# Recheck the workflow after execution
pixi run snakemake --snakefile workflow/visualization/Snakefile --cores 1 --dry-run
```

The workflow has been exercised with the synthetic example; Snakemake subsequently reported that its declared outputs were present and up to date. This confirms file-based execution and dependency tracking, **not** full clinical or molecular scientific validation.

For figure definitions, input conventions, and troubleshooting, see the [Visualization Workflow Guide](visualization_workflow.md).

### 7.2 Planned clinical and molecular Snakemake workflows

The **Clinical + RNA** and **Clinical + RNA + DNA** examples described in Sections 2–6 are design targets. Their harmonization rules, cohort-specific input configurations, QC checks, output contracts, and executable commands will be documented after implementation and testing. Do not run the proposed `cohorts:` YAML with the current visualization `Snakefile`.

For site-specific use, configure approved local inputs and outputs; do not hard-code personal workstation paths or copy controlled data into Git.

## 8. Expected output and QC records

### 8.1 Implemented visualization outputs

Outputs from the synthetic example are written to `results/visualization/example/`. The declared figures include:

- `01_cancer_donut.png`
- `02_treatment_donut.png`
- `03_clinical_availability_heatmap.png` and `03_clinical_availability_heatmap.pdf`
- `04_sex_by_cohort.png`
- `05_sampling_timing_by_cohort.png`
- `06_recist_by_cohort.png`

The workflow also produces figure-count CSVs, cohort summaries, variable missingness/availability reports, access summaries, conflict and assay-label reports, observed follow-up summaries, and `run_manifest.txt`.

These descriptive outputs facilitate review but are **not** substitutes for the full source-level, mapping, endpoint, assay, and release QC defined in the [Quality Control Framework](quality_control.md).

### 8.2 Proposed clinical and molecular outputs

For each planned cohort example, the target handoff is the following **proposed** structure, subject to source availability and approved sharing:

```text
<approved_output_root>/<cohort_id>/
├── clinical_harmonized.csv
├── rna_harmonized.*           # If RNA data are present
├── dna_harmonized.*           # Example 2, if DNA data are present
├── sample_map_validated.csv
├── integrated_mae.rds        # Optional, if produced
├── source_manifest.tsv
├── mapping_log.tsv
├── qc_summary.tsv
├── unresolved_issues.tsv
└── run_manifest.txt
```

The filenames and exact formats will be finalized with the molecular workflows. Record QC outcomes as **Pass**, **Pass with documented limitations**, or **Hold for review**, as defined in the [Quality Control Framework](quality_control.md). Cohort-level data availability does not establish analysis readiness.

## 9. Reproducibility and cross-site collaboration

For each run, preserve or reference:

- Source dataset version and approved location; checksums when allowed.
- Cohort configuration and applied mapping-rule version.
- Git commit and Pixi lockfile/environment details.
- RNA/DNA processing parameters, annotation resources, and software versions.
- QC results, unresolved mappings, permitted outputs, curator/reviewer information, and execution date.

The same workflow should produce structurally comparable outputs at UHN, UCL, and McGill without requiring raw or controlled datasets to cross institutional boundaries.

## 10. Troubleshooting and implementation status

| Issue | Recommended action |
| --- | --- |
| Snakemake command not found | Confirm `pixi install` completed, then check `pixi run snakemake --version`. |
| Pixi dependency installation fails | Inspect Python/package compatibility and the errors during environment resolution; document any environment changes. |
| Snakemake cannot find `workflow/visualization/Snakefile` | Run commands from the repository root, or provide the correct `--snakefile` path. |
| Input CSV not found | Check `config/visualization.yaml` and verify that the input path is accessible locally. |
| R script or package error | Inspect `logs/visualization/example.log` and confirm required R packages in the Pixi environment. |
| Snakemake reports nothing to do | Expected when all declared outputs are present and up to date. |
| Unexpected clinical values | Check source definitions and the mapping log; flag unsupported mappings rather than inferring values. |
| RNA gene IDs differ across cohorts | Verify ID type, source annotation, GENCODE release, and explicit conversion rules (planned molecular examples). |
| Patient/sample IDs fail to join | Inspect identifiers, duplicate records, and the verified cohort-patient-sample relationship (planned molecular examples). |
| DNA absent for Clinical + RNA example | Expected; the planned configuration sets `dna.enabled: false`. |
| Restricted input cannot be shared | Run locally within an approved environment and share only authorized outputs. |

**Implementation status:** The clinical visualization workflow is implemented. Both clinical/RNA/DNA example pipelines are planned; before calling them runnable, provide approved example data, finalize input/output contracts, implement and test Snakemake rules, validate dependencies, and confirm the QC reports produced.

---

## Document history

| Version | Date | Status | Summary |
| --- | --- | --- | --- |
| 1.0 | November 20, 2026 | Initial guide | Defined two planned clinical/molecular examples, input contracts, and reproducibility expectations. |