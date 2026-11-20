# MAR-40 Usage Guide

**Version:** 1.0  
**Scope:** Participating MAR-40 collaborators at UHN, UCL, and McGill University

## 1. Purpose

This guide describes how collaborators will prepare and run reproducible clinical and molecular data harmonization workflows for MAR-40. It complements the [Data Curation SOP](data_curation_SOP.md), [Data Dictionary](data_dictionary.md), [Quality Control Framework](quality_control.md), and [Data Sources Guide](data_sources.md).

The repository uses **Pixi** for environment management and is intended to use **Snakemake** to coordinate data preparation, harmonization, quality control (QC), and integration. **Commands shown as planned below must be validated against the repository's actual `pixi.toml`/`pixi.lock`, `Snakefile`, and rule definitions before they are treated as runnable.**

The workflow must be executable inside each site's approved computing environment. The presence of code or documentation does not authorize the movement of controlled-access or private data between institutions.

## 2. Two reference examples

The repository will provide two approved, shareable example cohorts to demonstrate different assay configurations.

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

Provide a cohort-specific configuration that identifies all available data and their formats. **The paths and filenames below illustrate a proposed example layout; they are not assertions that these files already exist.**

```text
data/
  rawdata/
    examples/
      example_clinical_rna/
        clinical.csv
        rna_expression.tsv
        sample_map.csv
      example_clinical_rna_dna/
        clinical.csv
        rna_expression.tsv
        dna_alterations.tsv
        sample_map.csv
  procdata/
  results/
```

### 4.1 Clinical metadata

The source file should contain a documented patient identifier, and any additional fields available for cancer type, histology, stage, age, sex, treatment, response, survival, and sampling timepoints. The source file **does not need to use standardized column names**: mappings to the MAR-40 target variables must be documented according to the [Data Dictionary](data_dictionary.md).

- Treat `(cohort, patientid)` as the unique patient key for cohort-level summaries unless a validated cross-cohort linkage exists.
- Preserve original source values in the approved environment; do not silently replace unrecognized codes.
- Document survival units, time origin, and event/censoring conventions before transformation.
- Missing optional clinical data are reported as missing, not treated as negative observations.

### 4.2 RNA expression

Document whether the input is counts, TPM, another normalized expression scale, or microarray data. Capture the platform, gene identifier system, genome build when relevant, normalization method, transformation, reference annotation release, and sample identifiers.

MAR-40 generally uses **GENCODE v19 for applicable published/processed datasets** and **GENCODE v40 for standardized reprocessing when raw data are available**; when a publication or source supplies a specific annotation release, retain that documented information. Do **not** assume a dataset used v19 solely because it is published or its annotation is unknown. Any gene-ID or genome-build conversion must be traceable.

### 4.3 DNA alterations (Example 2 only)

Document the actual assay and input representation (for example, SNV/indel calls, CNA segments, or a curated alteration matrix). Capture the genome build, variant annotation and filtering methods, sample IDs, and rules used to produce a gene-by-sample representation. **Do not assume all DNA datasets contain both SNV and CNA data.**

### 4.4 Patient-to-sample linkage

A sample mapping file or equivalent verified linkage must associate each assay sample with its clinical patient. Multiple samples per patient and different sample availability across assays are permitted, but ambiguous or unmatched IDs must be reported by QC.

## 5. Cohort-specific configuration

Use an explicit configuration rather than detecting DNA availability only by the presence of a filename. For example, a *proposed* YAML configuration is:

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

The commands below are **illustrative targets for implementation**, not currently verified executable commands. Before publishing them as operational instructions, confirm that `pixi.toml` includes Snakemake and that the repository contains a valid `Snakefile` with appropriate rules and targets.

```bash
# Example: inspect the workflow without executing it
pixi run snakemake --cores 4 --dry-run

# Example: execute the configured default targets
pixi run snakemake --cores 4
```

For site-specific execution, the finalized workflow should support selecting a cohort and approved local input/output paths through configuration. Do not hard-code individual workstation paths or require controlled datasets to be copied into the Git repository.

## 8. Expected output and QC records

For each cohort, aim to produce the following artifacts **where applicable and permitted**:

```text
<approved_output_root>/<cohort_id>/
  clinical_harmonized.csv
  rna_harmonized.*
  dna_harmonized.*             # Only if DNA is provided
  sample_map_validated.csv
  integrated_mae.rds          # If produced by the workflow
  source_manifest.tsv
  mapping_log.tsv
  qc_summary.tsv
  unresolved_issues.tsv
  run_manifest.txt
```

The naming convention is a proposed output contract. The exact filenames, assays, and serialization formats should be fixed in the workflow implementation and reflected in the SOP and QC documentation.

Record QC outcomes as **Pass**, **Pass with documented limitations**, or **Hold for review**, as defined by the [Quality Control Framework](quality_control.md). A cohort-level availability summary is not equivalent to analytical readiness.

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
| Required input missing | Verify the cohort configuration and approved path. |
| Unexpected clinical value | Check source definition; record the unmapped value and request review. |
| RNA gene IDs differ across datasets | Verify gene-ID type, GENCODE release, and explicit conversion rules. |
| Sample IDs fail to join | Inspect sample mapping, duplicated IDs, and cohort-level namespaces. |
| Missing DNA for Example 1 | Expected; confirm `dna.enabled: false`. |
| Snakemake reports no `Snakefile` or missing rule | The workflow is not yet implemented or the working directory is incorrect. |
| Restricted input cannot be shared | Execute locally within an approved environment; share only authorized outputs. |

**Implementation checklist:** Before calling the example workflows runnable, add approved example datasets, finalize the input/output contracts, implement and test Snakemake rules, validate the Pixi environment, and confirm expected QC reports for both assay configurations. Update this guide with the exact tested commands and expected results.

---

## Document history

| Version | Date | Status | Summary |
| --- | --- | --- | --- |
| 1.0 | November 20, 2026 | Active guide; workflow implementation pending | Defines two example cohorts, input contracts, proposed Pixi/Snakemake execution, outputs, QC, and cross-site reproducibility requirements. |
