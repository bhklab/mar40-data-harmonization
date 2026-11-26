
# MAR-40 Developer Notes

**Version:** 1.0  
**Scope:** Technical decisions, implementation notes, and reproducibility considerations for MAR-40 data standardization and harmonization.

## Overview

This document records technical decisions and reproducibility considerations for the MAR-40 data harmonization repository. Detailed procedures are available in the [Data Curation SOP](data_curation_SOP.md), [Clinical Metadata Standardization](clinical_metadata_standardization.md), [Molecular Data Standardization](molecular_data_standardization.md), and [Quality Control](quality_control.md) guides.

## Workflow Scope

- **Snakemake:** Supports clinical and molecular data curation, preprocessing, standardization, harmonization, and quality control. Current examples include the ICB_Hwang and cohort visualization workflows.

## Implementation Notes

- **Clinical standards:** Clinical mappings are informed by mCODE and ICGC-ARGO. Document source-to-standard mappings and unresolved discrepancies.
- **Molecular annotation:** Record reference genomes, gene identifiers, annotation versions, and assay-specific transformations. [AnnotationGx](https://github.com/bhklab/AnnotationGx) and [ICB_Common](https://github.com/BHKLAB-DataProcessing/ICB_Common) serve as reference resources; their integration and versions should be verified for each workflow.
- **Reproducibility:** Pixi manages declared workflow tools. R/Bioconductor and external script dependencies require documented versions and validation.
- **Data governance:** Keep restricted patient-level data in approved storage and share only authorized outputs.

## Decision Log

Record significant changes to shared definitions, workflows, dependencies, or output formats, including the **date, decision, rationale, affected files, and validation status**.
