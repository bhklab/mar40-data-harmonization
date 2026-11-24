# MAR-40 Data Harmonization and Standardization

**Author:** [Farnoosh Abbas Aghababazadeh](https://github.com/RibaA)  
**Contact:** [farnoosh.abbasaghababazadeh@uhn.ca](mailto:farnoosh.abbasaghababazadeh@uhn.ca)

**Description:** Standardized data curation, processing, and harmonization procedures, standard operating procedures (SOPs), quality control frameworks, and reproducible computational workflows for clinical and molecular data within the MAR-40 immuno-oncology research program.

---

[![Pixi](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/prefix-dev/pixi/main/assets/badge/v0.json&style=flat-square)](https://github.com/prefix-dev/pixi)
[![Ruff](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/astral-sh/ruff/main/assets/badge/v2.json&style=flat-square)](https://github.com/astral-sh/ruff)
[![Material for MkDocs](https://img.shields.io/badge/mkdocs--material-gray?logo=materialformkdocs&style=flat-square)](https://github.com/squidfunk/mkdocs-material)
[![Snakemake](https://img.shields.io/badge/workflow-Snakemake-blue?style=flat-square)](https://snakemake.github.io/)

![GitHub last commit](https://img.shields.io/github/last-commit/bhklab/mar40-data-harmonization?style=flat-square)
![GitHub issues](https://img.shields.io/github/issues/bhklab/mar40-data-harmonization?style=flat-square)
![GitHub pull requests](https://img.shields.io/github/issues-pr/bhklab/mar40-data-harmonization?style=flat-square)
![GitHub contributors](https://img.shields.io/github/contributors/bhklab/mar40-data-harmonization?style=flat-square)

## Overview

MAR-40 is a collaborative immuno-oncology research program integrating heterogeneous clinical and molecular datasets across participating institutions, including the University Health Network (UHN), University College London (UCL), and McGill University.

This repository provides a shared framework for consistent data curation, standardization, harmonization, quality control, and reproducible analyses across participating sites.

The project aims to:

- Standardize clinical and molecular metadata using common data dictionaries and controlled vocabularies.
- Harmonize cohort-specific variables, including cancer type, treatment, response, survival outcomes, sampling timepoints, and molecular assays.
- Document source-to-standard mappings, provenance, quality-control decisions, and unresolved discrepancies.
- Develop reproducible computational workflows using **Snakemake** for cohort processing and visualization and **Pixi** for workflow environment management.
- Support consistent cohort characterization and downstream immuno-oncology biomarker research.
- Promote data management aligned with the **FAIR principles** (Findable, Accessible, Interoperable, and Reusable).

## Set Up

### Prerequisites

[Pixi](https://pixi.sh/latest/) manages the project workflow environment. Follow the [Pixi installation instructions](https://pixi.sh/latest/) if needed.

The ICB_Hwang example also requires R with its scientific package dependencies. On the tested Windows system, Snakemake ran through Pixi and scientific processing used a locally installed **R 4.5.2**. The project Pixi environment should not be assumed to install R or Bioconductor packages automatically unless they are explicitly declared.

### Installation

1. Clone the repository and enter its root directory:

   ```bash
   git clone https://github.com/bhklab/mar40-data-harmonization.git
   cd mar40-data-harmonization
   ```

2. Install the available Pixi environment:

   ```bash
   pixi install
   ```

3. Confirm Snakemake is available:

   ```bash
   pixi run snakemake --version
   ```

See the [Usage Guide](docs/usage.md) for general setup and execution instructions.

## Workflows

### Clinical cohort visualization

The visualization workflow produces descriptive cohort summaries and figures from harmonized MAR-40 sample-level clinical metadata. A synthetic dataset is provided to test this workflow without using restricted patient-level data.

- **Example input:** `data/examples/MAR40_synthetic_sample_level.csv`
- **Required identifiers:** `cohort`, `patientid`, `sampleid`
- **Configuration:** `config/visualization.yaml`
- **Rule file:** `workflow/visualization/rules.smk`

From the repository root, preview the current visualization workflow:

```bash
pixi run snakemake --snakefile workflow/visualization/Snakefile --cores 1 --dry-run
```

Execute:

```bash
pixi run snakemake --snakefile workflow/visualization/Snakefile --cores 1
```

**Note:** These commands use the original visualization entry point. If visualization has been moved to its own dedicated `workflow/visualization/Snakefile`, use that entry point instead after validating its configuration.

Outputs include cancer type and immunotherapy treatment distributions; clinical variable availability; sex and RECIST distributions; pre-, on-, and post-treatment sampling summaries; and supporting counts, missingness reports, conflict records, and run metadata.

- **Outputs:** `results/visualization/example/`
- **Execution log:** `logs/visualization/example.log`

Collaborators can configure an approved local dataset in `config/visualization.yaml` without modifying the scientific visualization script. Descriptive outputs do not replace source-level validation or scientific approval.

See the [Visualization Workflow Guide](docs/visualization_workflow.md).

### Example 1: ICB_Hwang — Clinical + RNA

The Hwang immunotherapy cohort ([GEO GSE136961](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE136961)) serves as a reproducible example of clinical and RNA data harmonization using **R, Snakemake, and Pixi**.

The workflow integrates clinical metadata and RNA expression data into a **MultiAssayExperiment (MAE)**, with standardized sample identifiers and documented processing steps.

**Validated output:** 381 annotated genes, 21 RNA samples, and 21 matched clinical records.

**Workflow:** `workflow/icb_hwang/Snakefile`  
**Configuration:** `config/icb_hwang.yaml`  
**Data directory:** `data/examples/icb_hwang/`

Run from the repository root after configuring R and providing the required local inputs:

```bash
pixi run snakemake --snakefile workflow/icb_hwang/Snakefile --cores 1
```

**Status:** Successfully executed locally. Automated QC is planned for a future update.

For methodology, dependencies, and input requirements, see the [ICB_Hwang Example Documentation](docs/icb_hwang_example.md).

## Documentation

The repository documentation describes shared standards, workflows, and procedures.

| Document | Purpose |
| --- | --- |
| [Data Curation SOP](docs/data_curation_SOP.md) | Clinical and molecular curation, processing, and harmonization procedures. |
| [Data Dictionary](docs/data_dictionary.md) | Standardized variables, definitions, units, and permitted values. |
| [Data Sources](docs/data_sources.md) | Cohort provenance, molecular availability, and access conditions. |
| [Quality Control](docs/quality_control.md) | Validation principles, missingness, and consistency assessment. |
| [Usage Guide](docs/usage.md) | Running workflows and reproducing outputs. |
| [Visualization Workflow](docs/visualization_workflow.md) | Visualization workflow, figures, reports, and troubleshooting. |
| [ICB_Hwang Example](docs/icb_hwang_example.md) | Clinical + RNA data harmonization and MAE construction. |
| [Development Notes](docs/devnotes.md) | Technical notes and development decisions. |

## Data Curation and Harmonization Workflow

The MAR-40 framework comprises six main stages, described in the [Data Curation SOP](docs/data_curation_SOP.md):

1. **Data acquisition and provenance:** Identify cohorts, publications, source datasets, versions, and access permissions.
2. **Clinical metadata curation:** Review patient and sample identifiers, demographics, cancer classifications, treatment, response, and survival variables.
3. **Molecular data preparation:** Document assay modalities, processing methods, annotations, and sample relationships.
4. **Harmonization:** Apply the shared data dictionary, controlled vocabularies, and documented source-to-standard mappings.
5. **Quality control:** Assess missingness, duplicates, conflicting fields, assay links, and unresolved mappings.
6. **Reproducible outputs:** Produce standardized tables, descriptive figures, QC summaries, and provenance records using version-controlled methods.

Missing values should not be treated as negative observations. Patient-, sample-, treatment-, and timepoint-specific variables must remain distinguishable; longitudinal changes are not automatically conflicts.

Follow the [Data Curation SOP](docs/data_curation_SOP.md) and [Quality Control Guide](docs/quality_control.md) for detailed procedures.

## Repository Organization

```text
mar40-data-harmonization/
├── config/                   # Workflow configurations
├── data/
│   ├── examples/             # Synthetic examples and local cohort example folders
│   │   └── icb_hwang/        # Hwang download/, annot/, curation/ (data ignored)
│   ├── rawdata/              # Other approved local source data
│   └── procdata/             # Other approved local processed data
├── docs/                     # SOPs, dictionaries, workflow documentation
├── metadata/                 # Project metadata and supporting records
├── resources/                # Reference resources
├── workflow/
│   ├── Snakefile             # Existing visualization entry point
│   ├── icb_hwang/
│   │   └── Snakefile         # Separate Hwang entry point
│   ├── rules/                # Snakemake rules for each workflow
│   └── scripts/              # Scientific R scripts
├── results/                  # Generated outputs (ignored)
├── logs/                     # Workflow logs (ignored)
├── pixi.toml                 # Environment specification
└── pixi.lock                 # Resolved dependencies
```

See the [Raw Data README](data/rawdata/README.md) and [Processed Data README](data/procdata/README.md) for other directory conventions.

### Data Access and Sharing

Dataset access is governed by source-specific permissions, institutional requirements, and applicable ethics and data-sharing agreements. Private or controlled-access patient-level datasets must **not** be committed to a public repository. Restricted data must remain in approved institutional storage.

The repository shares code, standards, configurations, documentation, and synthetic or explicitly authorized example resources. Keeping data local does not prevent reproducible processing, provided sources, versions, and setup instructions are documented.

## Reproducibility and FAIR Data Principles

MAR-40 supports transparent, reproducible, and **FAIR (Findable, Accessible, Interoperable, and Reusable)**-aligned management of clinical and molecular data. Standardized metadata, controlled vocabularies, documented mappings, and reproducible workflows promote interoperability and traceability while respecting governance requirements.

### Reproducibility

The repository supports reproducible research through:

- **Shared standards:** Data dictionaries, controlled vocabularies, and documented harmonization decisions.
- **Version-controlled methods:** Snakemake rules, scientific scripts, and workflow configurations.
- **Managed workflow environments:** Pixi specifications and lockfiles for declared dependencies.
- **Traceable outputs:** Cohort summaries, provenance, and available workflow logs.
- **Dependency-aware execution:** Snakemake rebuilds outputs when relevant inputs or scripts change.

Full cross-site reproducibility also requires versioned R/Bioconductor and external ICB_Common dependencies; these remain ongoing improvements.

## Contributions

Collaborators are encouraged to propose improvements to data standards, documentation, validation procedures, and reproducible workflows. Changes to shared clinical definitions, mappings, and reporting conventions should be reviewed across participating sites before adoption.

Contributions must preserve provenance and comply with dataset access restrictions. Do not include private or controlled-access source data in pull requests, issues, or example files.
