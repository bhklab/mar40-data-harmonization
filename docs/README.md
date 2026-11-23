# MAR-40 Data Harmonization and Standardization

**Author:** [Farnoosh Abbas Aghababazadeh](https://github.com/RibaA)  
**Contact:** [farnoosh.abbasaghababazadeh@uhn.ca](mailto:farnoosh.abbasaghababazadeh@uhn.ca)

**Description:** Development of standardized data curation, processing, and harmonization procedures, standard operating procedures (SOPs), quality control frameworks, and reproducible computational workflows for clinical and molecular data within the MAR-40 immuno-oncology research program.

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
- Develop reproducible computational workflows, currently using **Snakemake** for cohort visualization and **Pixi** for environment management.
- Support consistent cohort characterization and downstream immuno-oncology biomarker research.
- Promote data management practices aligned with the **FAIR principles** (Findable, Accessible, Interoperable, and Reusable).

## Set Up

### Prerequisites

[Pixi](https://pixi.sh/latest/) manages the project environment and software dependencies. Follow the [Pixi installation instructions](https://pixi.sh/latest/) if it is not already installed.

### Installation

1. Clone the repository and enter its root directory:

   ```bash
   git clone https://github.com/bhklab/mar40-data-harmonization.git
   cd mar40-data-harmonization
   ```

2. Install the project environment:

   ```bash
   pixi install
   ```

3. Verify that Snakemake is available:

   ```bash
   pixi run snakemake --version
   ```

See the [Usage Guide](docs/usage.md) for general setup and workflow instructions.

## Quick Start: Reproducible Cohort Visualization

The repository includes a **Snakemake workflow** for descriptive cohort characterization and visualization using harmonized MAR-40 sample-level clinical metadata. A synthetic example dataset is supplied so collaborators can test the workflow without accessing restricted patient-level data.

**Example input:** `data/examples/MAR40_synthetic_sample_level.csv`  
**Required identifiers:** `cohort`, `patientid`, `sampleid`  
**Configuration:** `config/visualization.yaml`

From the repository root, preview the workflow:

```bash
pixi run snakemake \
  --snakefile workflow/Snakefile \
  --cores 1 \
  --dry-run
```

Execute the workflow:

```bash
pixi run snakemake \
  --snakefile workflow/Snakefile \
  --cores 1
```

The workflow produces:

- Cancer type and immunotherapy treatment distributions.
- Clinical variable availability across cohorts.
- Sex and RECIST distributions by cohort.
- Pre-, on-, and post-treatment sampling distributions.
- Supporting counts, cohort summaries, missingness reports, conflict records, and run metadata.

**Outputs:** `results/visualization/example/`  
**Execution log:** `logs/visualization/example.log`

Collaborators can specify an approved local harmonized dataset through `config/visualization.yaml` without changing the visualization script. The same variable definitions, missing-value conventions, and color mappings should be used across sites.

These descriptive outputs support cohort review but are not a substitute for source-level validation, endpoint assessment, or scientific approval. See the [Visualization Workflow Guide](docs/visualization_workflow.md) for more detailed instructions and troubleshooting.

> **Implementation scope:** The current Snakemake module produces descriptive cohort visualizations from **already harmonized** metadata. Source-specific clinical curation, RNA/DNA processing, and multi-omics integration are separate components of the broader MAR-40 framework; they should not be assumed to be implemented by this visualization module.

## Documentation

The repository documentation describes shared standards, workflows, and procedures.

| Document | Purpose |
| --- | --- |
| [Data Curation SOP](docs/data_curation_SOP.md) | Clinical and molecular data curation, processing, and harmonization procedures. |
| [Data Dictionary](docs/data_dictionary.md) | Standardized variables, definitions, units, and permitted values. |
| [Data Sources](docs/data_sources.md) | Cohort provenance, source information, molecular availability, and data access conditions. |
| [Quality Control](docs/quality_control.md) | Validation, missingness assessment, consistency checks, and QC reporting. |
| [Usage Guide](docs/usage.md) | General instructions for running workflows and reproducing outputs. |
| [Visualization Workflow](docs/visualization_workflow.md) | Snakemake-based cohort characterization, figures, reports, and troubleshooting. |
| [Development Notes](docs/devnotes.md) | Technical notes and development decisions. |

## Data Curation and Harmonization Workflow

The MAR-40 framework comprises six main stages, as described in the [Data Curation SOP](docs/data_curation_SOP.md):

1. **Data acquisition and provenance:** Identify cohorts, publications, source datasets, versions, and access permissions.
2. **Clinical metadata curation:** Review patient and sample identifiers, demographics, cancer classifications, treatment, response, and survival variables.
3. **Molecular data preparation:** Document assay modalities, processing methods, annotations, and sample relationships.
4. **Harmonization:** Apply the shared data dictionary, controlled vocabularies, and documented source-to-standard mappings.
5. **Quality control:** Assess missingness, duplicate records, conflicting fields, assay links, and unresolved mappings.
6. **Reproducible outputs:** Produce standardized tables, descriptive figures, QC summaries, and provenance records using version-controlled methods.

Missing values may occur for individual records or entire cohorts and should not be treated as negative observations. Patient-level, sample-level, treatment-level, and timepoint-specific variables must be distinguished when preparing analyses; longitudinal changes in treatment or response are not automatically data conflicts.

Follow the [Data Curation SOP](docs/data_curation_SOP.md) and [Quality Control Guide](docs/quality_control.md) for detailed procedures.

## Repository Organization

```text
mar40-data-harmonization/
├── config/             # Shared workflow configurations
├── data/
│   ├── examples/       # Version-controlled synthetic/shareable examples
│   ├── rawdata/        # Original source data (approved local storage)
│   └── procdata/       # Processed/harmonized data (approved local storage)
├── docs/               # SOPs, dictionaries, and workflow documentation
├── metadata/           # Project metadata and supporting records
├── resources/          # Reference resources
├── workflow/
│   ├── Snakefile       # Snakemake entry point
│   ├── rules/          # Reusable Snakemake rules
│   └── scripts/        # R/Python analysis scripts
├── results/            # Generated outputs (not committed)
├── logs/               # Workflow logs (not committed)
├── pixi.toml           # Environment and dependency specification
└── pixi.lock           # Resolved dependency versions
```

See the [Raw Data README](data/rawdata/README.md) and [Processed Data README](data/procdata/README.md) for directory-specific conventions.

### Data Access and Sharing

Dataset access is governed by source-specific permissions, institutional requirements, and applicable ethics and data-sharing agreements. Private or controlled-access patient-level datasets must **not** be committed to the public repository. Restricted data must remain in approved institutional storage.

The repository shares code, standards, configurations, documentation, and synthetic or otherwise explicitly authorized examples. Workflow reproducibility does not require unrestricted access to the original datasets.

## Reproducibility and FAIR Data Principles

MAR-40 supports transparent, reproducible, and **FAIR (Findable, Accessible, Interoperable, and Reusable)**-aligned management of clinical and molecular data across collaborating institutions. Standardized metadata, controlled vocabularies, documented mappings, and reproducible workflows promote interoperability, traceability, and reuse while respecting institutional data governance requirements.

### Reproducibility

The repository supports reproducible research through:

- **Shared standards:** Data dictionaries, controlled vocabularies, and documented harmonization decisions.
- **Version-controlled methods:** Snakemake rules, reusable scripts, and workflow configurations.
- **Managed environments:** Pixi specifications and lockfiles for dependency consistency.
- **Traceable outputs:** Cohort summaries, missingness and conflict reports, input provenance, and execution metadata.
- **Automated execution:** Dependency-aware workflow runs that can reproduce results and avoid unnecessary computation.

Snakemake is currently used for workflow orchestration. **Nextflow** support may be introduced in the future, reusing the same validated scripts and standardized inputs and outputs.

## Contributions

Collaborators are encouraged to propose improvements to data standards, documentation, validation procedures, and reproducible workflows. Changes to shared clinical definitions, mappings, and reporting conventions should be reviewed across participating sites before adoption.

Contributions must preserve provenance and comply with dataset access restrictions. Do not include private or controlled-access source data in pull requests, issues, or example files.
