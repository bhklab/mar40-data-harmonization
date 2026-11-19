# MAR-40 data harmonization and standardization

**Authors:** [Farnoosh Abbas Aghababazadeh](https://github.com/RibaA) 

**Contact:** [farnoosh.abbasaghababazadeh@uhn.ca](mailto:farnoosh.abbasaghababazadeh@uhn.ca) 

**Description:** Development of standardized data processing and harmonization procedures, standard operating procedures (SOPs), quality control frameworks, and reproducible Snakemake workflows for clinical and molecular data in the MAR-40 immuno-oncology research program.

---

[![pixi-badge](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/prefix-dev/pixi/main/assets/badge/v0.json&style=flat-square)](https://github.com/prefix-dev/pixi)
[![Ruff](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/astral-sh/ruff/main/assets/badge/v2.json&style=flat-square)](https://github.com/astral-sh/ruff)
[![Built with Material for MkDocs](https://img.shields.io/badge/mkdocs--material-gray?logo=materialformkdocs&style=flat-square)](https://github.com/squidfunk/mkdocs-material)

![GitHub last commit](https://img.shields.io/github/last-commit/bhklab/mar-40-data-harmonization-and-standardization?style=flat-square)
![GitHub issues](https://img.shields.io/github/issues/bhklab/mar-40-data-harmonization-and-standardization?style=flat-square)
![GitHub pull requests](https://img.shields.io/github/issues-pr/bhklab/mar-40-data-harmonization-and-standardization?style=flat-square)
![GitHub contributors](https://img.shields.io/github/contributors/bhklab/mar-40-data-harmonization-and-standardization?style=flat-square)
![GitHub release (latest by date)](https://img.shields.io/github/v/release/bhklab/mar-40-data-harmonization-and-standardization?style=flat-square)

## Overview

MAR-40 is a collaborative immuno-oncology research program that integrates heterogeneous clinical and molecular datasets across participating institutions. This repository supports consistent and reproducible data curation, standardization, harmonization, and quality control across collaborating sites.

The project aims to:

- Standardize clinical and molecular metadata using common data dictionaries and controlled vocabularies.
- Harmonize cohort-specific fields for cancer type, treatment, response, survival outcomes, and molecular assays.
- Document source-to-standard mappings, provenance, quality-control decisions, and unresolved discrepancies.
- Support reproducible computational workflows and downstream immuno-oncology biomarker analyses.

## Set Up

### Prerequisites

[Pixi](https://pixi.sh/latest/) is used to manage the project environment. If it is not yet installed, follow the [Pixi installation instructions](https://pixi.sh/latest/).

### Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/bhklab/mar40-data-harmonization.git
   ```

2. Navigate to the repository:

   ```bash
   cd mar40-data-harmonization
   ```

3. Install the project environment:

   ```bash
   pixi install
   ```
For commands to run the available workflows, see [Usage](docs/usage.md).

## Documentation

View the full documentation at [MAR-40 data harmonization](https://bhklab.github.io/mar40-data-harmonization/).

| Document | Purpose |
| --- | --- |
| [Data Curation SOP](docs/data_curation_SOP.md) | Step-by-step clinical and molecular data curation, processing, and harmonization procedures. |
| [Data Dictionary](docs/data_dictionary.md) | Standardized fields, definitions, units, and permitted values. |
| [Data Sources](docs/data_sources.md) | Cohort provenance, source documentation, and data access. |
| [Quality Control](docs/quality_control.md) | Validation, missingness, consistency checks, and QC reporting. |
| [Usage](docs/usage.md) | Instructions for running workflows and reproducing outputs. |
| [Development Notes](docs/devnotes.md) | Technical notes and development decisions. |

### Data curation and harmonization workflow

1. **Data acquisition and provenance:** Identify source cohorts, publications, datasets, access permissions, and source versions.
2. **Clinical metadata curation:** Review patient/sample identifiers, demographics, disease classifications, treatments, responses, and survival endpoints.
3. **Molecular data preparation:** Document assay modalities, processing methods, and molecular annotations.
4. **Harmonization:** Apply the shared data dictionary, controlled vocabularies, and documented source-to-standard mapping decisions.
5. **Quality control:** Check missing values, duplicated records, conflicting fields, assay links, and unresolved mappings.
6. **Reproducible outputs:** Produce standardized files, QC summaries, and provenance records using version-controlled workflows.

Follow the [Data Curation SOP](docs/data_curation_SOP.md) for detailed procedures and [Quality Control](docs/quality_control.md) for checks and review expectations.

## Data Organization

| Directory | Contents |
| --- | --- |
| `data/rawdata/` | Original source data and source-specific documentation. |
| `data/procdata/` | Processed and harmonized clinical and molecular data. |
| `data/results/` | Generated summary tables, figures, and analysis outputs. |

See the [Raw Data README](data/rawdata/README.md) and [Processed Data README](data/procdata/README.md) for directory-specific conventions.

**Data access:** Do not commit private or controlled-access patient-level datasets to a public repository. Store restricted data only in approved environments; commit only documentation, code, and appropriately authorized example or synthetic data.

## Reproducibility

Collaborators should follow the shared SOP and dictionary, use version-controlled scripts and configurations, document mapping decisions and unresolved cases, review QC results, and record input provenance and software versions. These practices allow data preparation steps to be reviewed and rerun consistently across participating sites.
