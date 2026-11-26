
# MAR-40 Molecular Data Standardization and Annotation

**Version:** 1.0  
**Scope:** RNA and DNA data preprocessing, annotation, harmonization, and quality control across MAR-40 cohorts.  

## Overview

This document describes molecular data standardization procedures for MAR-40. Snakemake supports reproducible data curation, preprocessing, harmonization, and quality control.

UHN coordinates RNA-focused workflows, while UCL coordinates DNA-focused workflows. Both institutional inventories may include multiple molecular assay types.

Detailed workflow implementations and cohort-specific processing decisions should be documented alongside the relevant scripts and configurations.

## Molecular Data Inventory

For each cohort and assay, document:

- Cohort, patient and sample identifiers, specimen type, and collection timepoint.
- Molecular assay, data source, input format, and raw/processed data availability.
- Reference genome, gene annotation release, and molecular feature identifiers.
- Quantification or variant-calling method, normalization, and measurement units.
- Software versions, data access restrictions, and QC status.

## RNA Data Processing and Harmonization

1. **Input data:** Identify FASTQ, raw counts, TPM, FPKM, log-transformed expression, microarray, or targeted expression profiles.
2. **Expression quantification:** Document the reference transcriptome, quantification method, and gene-level summarization when processing raw RNA-seq data.
3. **Expression standardization:** Preserve original measurement scales and transformations. Apply cohort-appropriate normalization and filtering procedures.
4. **Gene annotation:** Harmonize gene identifiers using documented annotation references and releases, retaining source identifiers and mapping results.
5. **Sample matching:** Link molecular profiles to clinical metadata using validated patient and sample identifiers, preserving distinct specimens and collection timepoints.
6. **Quality control:** Assess sample and feature completeness, duplicate identifiers, annotation coverage, and assay-specific QC metrics.

## DNA Data Processing and Harmonization

1. **Input data:** Document sequencing modality (panel, WES, or WGS), reference genome, variant-calling pipeline, and input format.
2. **Variant annotation:** Standardize gene and variant identifiers, mutation consequences, and reference genome coordinates.
3. **Genomic alterations:** Maintain consistent representations of SNVs, indels, and copy-number alterations, with documented rules for deriving gene-level features.
4. **Tumor mutational burden:** Record whether TMB is source-reported or calculated, including mutation inclusion criteria, assay coverage, and callable territory.
5. **Sample matching:** Verify patient and tumor sample identifiers and assess potential duplicate samples across cohorts.
6. **Quality control:** Document sequencing coverage, tumor purity, variant filtering, and other assay-specific metrics when available.

## Annotation Tools and Reference Resources

The following BHK Lab resources can guide molecular annotation and cohort processing:

- **[AnnotationGx](https://github.com/bhklab/AnnotationGx):** Reference tools for molecular feature annotation and identifier mapping.
- **[ICB_Common](https://github.com/BHKLAB-DataProcessing/ICB_Common):** Shared conventions and scripts for immunotherapy cohort processing and harmonization.

Reference resources such as GENCODE, Ensembl, and HGNC should be documented with their release versions and identifier mappings.

Any external scripts or annotation tools integrated into MAR-40 should be version-controlled and validated before use.

## Quality Control and Reproducibility

For each processed cohort, record input/output sample counts, molecular feature counts, clinical matching, annotation coverage, filtering decisions, and unresolved discrepancies.

Preserve processing configurations, software versions, reference annotations, and provenance to support reproducibility and FAIR-aligned data management.

Restricted patient-level molecular data must remain in approved institutional storage. Only authorized outputs, documentation, and code should be shared through the repository.

