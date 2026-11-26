
# MAR-40 Clinical Metadata Standardization

**Version:** 1.0  
**Scope:** Clinical metadata curation, standardization, harmonization, and validation across MAR-40 immunotherapy cohorts.  

## Overview

This document describes the clinical metadata standardization framework for MAR-40. The framework is informed by selected common oncology data elements and definitions from mCODE and ICGC-ARGO, adapted to the available clinical data and research objectives.

Source variables, original definitions, transformation rules, and mapping decisions are preserved to support reproducibility and FAIR-aligned data management. This approach does not imply full compliance with either standard.

## Core Clinical Metadata

| Domain | Core information | Validation considerations |
| --- | --- | --- |
| Patient and sample | `cohort`, `patientid`, `sampleid`, specimen relationships | Distinguish patient-, specimen-, sample-, and assay-level records |
| Disease | Cancer type, histology, stage, metastatic status | Document classification standards; avoid inferring missing values |
| Therapy | Treatment agents, drug targets, combinations, treatment line, exposure dates | Distinguish treatment regimen, molecular target, and subsequent therapies |
| Sampling | Pre-, on-, and post-treatment sampling, specimen source and timepoint | Define timing relative to treatment and preserve longitudinal samples |
| Response | RECIST or study-defined criteria, response category, assessment time | Preserve original response definitions and document derived R/NR classifications |
| Survival | OS/PFS time, event status, units, time origin, censoring | Validate endpoint definitions and event coding |
| Data access and provenance | Access classification, study identifier, data source and version | Preserve provenance and comply with data access restrictions |

## Source-to-Standard Mapping

For each cohort:

1. Document the source dataset, version, and clinical data structure.
2. Identify original variable names, definitions, and permitted values.
3. Map source variables to standardized MAR-40 fields using documented rules.
4. Preserve missing, ambiguous, and unmapped values for review.
5. Validate patient and sample identifiers, specimen relationships, and collection timepoints.
6. Assess variable completeness, consistency, duplicates, and endpoint definitions.
7. Generate standardized clinical tables and mapping/QC summaries.

## Special Considerations

- **Treatment response:** Response criteria may differ across cohorts, including RECIST, RANO, pathological response, and study-defined classifications. Original categories should be retained, with harmonized response definitions documented separately.
- **Survival outcomes:** Preserve original time origins, units, event definitions, and censoring information. Analysis-specific censoring rules should not replace source metadata.
- **Patient and sample duplication:** Evaluate potential duplicate patients or samples within and across cohorts before calculating combined patient totals.
- **Missing data:** Distinguish missing, unavailable, and not applicable values. Missing clinical information should not be interpreted as a negative observation.
- **FAIR principles:** Apply consistent identifiers, documented metadata definitions, provenance tracking, and controlled-access procedures to improve data findability, interoperability, and reuse.
