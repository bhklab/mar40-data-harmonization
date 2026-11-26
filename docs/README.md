# MAR-40 Data Harmonization and Standardization

**Scope:** Clinical and molecular cohort curation, data standardization, QC, and reproducible preprocessing for MAR-40.

MAR-40 integrates heterogeneous immuno-oncology cohorts from University Health Network (UHN), University College London (UCL), and Université de Montréal / CHUM. This repository provides shared standards, documentation, and local **Snakemake** workflows for preparing standardized datasets. **Nextflow** is planned for downstream analyses across the broader MAR-40 research program; this repository does not claim those workflows are implemented here.

The framework promotes **FAIR** (Findable, Accessible, Interoperable, Reusable) practices while keeping restricted patient-level data in approved environments.

## Documentation

| Guide | Scope |
| --- | --- |
| [Data Curation and Harmonization SOP](data_curation_SOP.md) | Overall procedure, governance, processing and QC |
| [Clinical Metadata Standardization](clinical_metadata_standardization.md) | mCODE/ICGC-ARGO-informed mappings, outcomes and provenance |
| [Molecular Data Standardization](molecular_data_standardization.md) | RNA and DNA data processing, identifiers, gene annotations and QC |
| [Data Dictionary](data_dictionary.md) | Target fields, source-to-target mappings and conventions |
| [Data Sources](data_sources.md) | Cohort provenance and access |
| [Quality Control](quality_control.md) | Curation and release checks |
| [Usage Guide](usage.md) | Local setup and execution |
| [Clinical Visualization](visualization_workflow.md) | Cohort plots and reports |
| [ICB_Hwang Example](icb_hwang_example.md) | Clinical/RNA harmonization example |
| [Development Notes](devnotes.md) | Technical notes and decisions |

## Getting started

[Pixi](https://pixi.sh/latest/) supplies the workflow environment. The Hwang example additionally uses a separately installed R/Bioconductor environment (tested with R 4.5.2); Pixi is not assumed to install those dependencies automatically.

```bash
git clone https://github.com/bhklab/mar40-data-harmonization.git
cd mar40-data-harmonization
pixi install
pixi run snakemake --version
```

### Example: clinical and RNA cohort

```bash
pixi run snakemake --snakefile workflow/icb_hwang/Snakefile --cores 1
```

The Hwang (GSE136961) example has been run locally (21 matched clinical/RNA records; 381 annotated genes in the output MAE). Automated QC and broader cohort validation remain ongoing. See the [Hwang example guide](icb_hwang_example.md).

### Example: cohort characterization

```bash
pixi run snakemake --snakefile workflow/visualization/Snakefile --cores 1 --dry-run
pixi run snakemake --snakefile workflow/visualization/Snakefile --cores 1
```

The visualization workflow supports standardized cohort summary outputs and a synthetic example. See the [visualization guide](visualization_workflow.md).

## Repository structure

```text
config/                         # Workflow configuration
workflow/icb_hwang/             # Snakemake example, clinical + RNA
workflow/visualization/         # Snakemake characterization workflow
docs/                           # Documentation and SOP
data/examples/                  # Synthetic/authorized local examples
data/rawdata/                   # Approved local source-data conventions
data/procdata/                  # Approved local processed-data conventions
metadata/                       # Project metadata
pixi.toml, pixi.lock           # Workflow environment
```

[Raw data conventions](../data/rawdata/README.md) · [Processed data conventions](../data/procdata/README.md)

## Reference implementations

- [BHK Lab AnnotationGx](https://github.com/bhklab/AnnotationGx): an annotation resource/package to evaluate for reproducible feature-annotation steps. Verify functions, species, database releases and identifier mapping before adoption.
- [BHKLAB-DataProcessing ICB_Common](https://github.com/BHKLAB-DataProcessing/ICB_Common): shared ICB cohort-processing scripts and conventions used as a reference for cohort workflows. Pin the exact commit/version of any imported code.

See the [molecular standardization guide](molecular_data_standardization.md) for details. These references do **not** imply that all functions or QC rules have already been implemented in MAR-40.

## Data governance and contributions

Keep private/controlled patient-level data, credentials and restricted outputs out of this public repository. Use approved institutional storage and share only authorized code, metadata, synthetic examples or results. Document mappings, dependency versions, QC outcomes and scientific decisions in pull requests and approved project records.
