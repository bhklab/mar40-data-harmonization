# Clinical Metadata Standardization

**Status:** MAR-40 harmonization guidance. Source-to-target mappings require cohort-level review; this is not a claim of full mCODE or ICGC-ARGO compliance.

## Standards alignment

The MAR-40 clinical data dictionary is **informed by selected common oncology data elements and definitions from mCODE and ICGC-ARGO**. Adopt only variables that fit the available evidence and intended analyses. Retain source terms, transformation rules and mapping decisions.

| Domain | Core information | Critical validation |
| --- | --- | --- |
| Patient and sample | `cohort`, `patientid`, `sampleid`, specimen relationships | Keep patient-, specimen-, sample- and assay-level records separate |
| Disease | Primary cancer type, histology/subtype, stage, metastatic status | Document ontology/taxonomy version; do not infer from study title |
| Therapy | Agents, PD-1/PD-L1/CTLA-4 targets, combinations, therapy line, exposure dates | Distinguish regimen from molecular target and from subsequent therapies |
| Sampling | Pre/on/post treatment, sample date/timepoint, tissue source | Define time relative to an index exposure; preserve longitudinal records |
| Response | RECIST or study-defined response, R/NR mappings, assessment time | Preserve original categories; derived binary outcomes must name criteria |
| Outcomes | OS/PFS time, event indicator, unit, time origin, censoring | Validate event coding, time origin, handling of missing or competing data |
| Access/provenance | Access class, study ID, publication, source file/version | No patient-level restricted data in GitHub |

## Source-to-standard mapping checklist

1. Register source file/version, population, assay and record granularity.
2. Record the original field name, allowed values and study definition.
3. Map to a MAR-40 target variable with documented rule and reason.
4. Preserve unrecognized values as unresolved rather than inferring them.
5. Review patient/sample relationships and longitudinal timepoints.
6. Validate units, endpoint definitions, missingness, duplicates and mapping exceptions.
7. Export standardized tables and a versioned QC/mapping report as permissions allow.

## Special considerations

- **Response:** Different trials may define response using RECIST, RANO, pathological response, or PFS-derived criteria. Do not treat these as interchangeable without a documented analysis-specific mapping.
- **Survival:** Preserve event and time origin; do not impose a universal follow-up censoring time as part of raw harmonization.
- **Deduplication:** Potential duplicates within and across institutional inventories need cohort/patient-level review. Site totals must not be summed as unique patients without linkage evidence.
- **FAIR:** Use stable identifiers, controlled terms, versioned mappings and access descriptors. FAIR does not require open release of restricted patient-level data.

