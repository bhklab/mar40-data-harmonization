# MAR-40 Data Sources and Cohort Registry

**Version:** 1.0  
**Status:** Active  
**Date:** November 20, 2026  
**Scope:** MAR-40 participating teams at UHN, UCL, McGill University, and other authorized collaborating sites  
**Repository location:** `docs/data_sources.md`  
**Related documentation:** [Data Curation SOP](data_curation_SOP.md) · [Data Dictionary](data_dictionary.md) · [Quality Control](quality_control.md) · [Usage](usage.md)

## 1. Purpose and scope

This document defines how contributing teams register and describe the clinical and molecular immuno-oncology cohorts used in MAR-40. It establishes a consistent **cohort-level source inventory**, not a common patient-level data model or an OMOP conversion requirement.

The objectives are to:

- Provide an auditable description of each cohort's origin, scientific scope, and permitted use.
- Record whether clinical variables and molecular assays are available, and in what form.
- Capture annotation versions, processing methods, and sample/patient counts with clear definitions.
- Enable reproducible curation, harmonization, QC, and descriptive cohort summaries across sites.
- Support collaboration when patient-level or raw files must remain within approved institutional environments.

**The registry does not authorize transfer or release of data.** Permissions are determined by ethics approvals, agreements, source licenses, and institutional policies.

## 2. Registry structure and record granularity

Use `config/cohort_registry_template.csv` as the shared, machine-readable schema. Maintain the populated cohort registry in an approved location, with only explicitly authorized metadata committed to the repository. Register one row per **cohort and source release**. If an independently processed cohort release differs substantially in data content or provenance, register it as a separate version. Each row must have a unique `registry_id`.

A cohort is a source-defined analysis population. It may contain multiple treatment arms, tumor types, molecular assays, patients, specimens, and sampling timepoints. Use companion manifests when these cannot be represented accurately by a single row:

- **Source manifest:** original files, hashes, locations, access conditions, and source releases.
- **Assay manifest:** one row per assay/data object with platform, sample coverage, reference versions, and preprocessing.
- **Mapping log:** source-variable-to-MAR-40 mappings, transformations, decisions, and unresolved issues.
- **QC summary:** executed checks, outcomes, reviewer decisions, and limitations.

Do not combine patient, sample, specimen, or assay counts into a single field. Counts in the registry are descriptive and must specify their unit.

## 3. Cohort identification and provenance

| Registry field | Description / recording rule |
| --- | --- |
| `registry_id` | Unique stable identifier for this cohort/release entry. |
| `cohort_id` | Stable MAR-40 cohort identifier; avoid collisions across sites. |
| `cohort_name` | Human-readable published or source name. |
| `contributing_site` | Site responsible for this registry entry (e.g., UHN, UCL, McGill). |
| `source_type` | `Publication`, `Repository`, `Clinical study`, `Institutional`, or `Other`. |
| `publication_doi` | DOI when available; otherwise leave blank. |
| `source_accession` | GEO/SRA/EGA/dbGaP or other source accession when applicable. |
| `source_reference` | Publication URL, data-provider reference, or descriptive source ID. Do not record restricted direct-access URLs or credentials in public files. |
| `study_design` | `Interventional`, `Observational`, `Retrospective`, `Other`, or `Unknown` as supported. |
| `source_release` | Original source release, dataset version, or documented snapshot. |
| `source_retrieval_date` | Retrieval or receipt date (`YYYY-MM-DD`) if applicable. |
| `curator` | Team/role or approved contact responsible for registration. |
| `last_reviewed` | Last scientific/technical review date (`YYYY-MM-DD`). |
| `registry_status` | `Registered`, `In curation`, `Harmonized`, `QC reviewed`, or `On hold`. This is workflow status, not data quality. |

Use `Unknown` (or blank where appropriate) when information is not established. Do not fabricate accession numbers, versions, publications, or collection dates.

## 4. Access classification and permissions

Record the access classification **based on actual source-level restrictions**, not whether a team can currently view a file.

| Access type | Definition |
| --- | --- |
| `Public` | The source is publicly accessible under stated terms; reuse restrictions may still apply. |
| `Controlled access` | Access requires authorization, a data access request, or contractual/ethics conditions. |
| `Private` | Locally or privately provided data not generally accessible through a public or controlled repository. |
| `Mixed` | Source components have different access classifications; resolve at file/assay level in the source manifest. |
| `Unknown` | Classification cannot yet be confirmed; flag for review. |

Store the registry fields `access_type`, `access_reference`, `permitted_processing_location`, `cross_site_sharing_status`, and `restrictions_notes`. For `cross_site_sharing_status`, use `Permitted`, `Restricted`, `Not permitted`, or `Pending verification`; this is **not** inferred from `access_type`.

**Never commit** patient-level restricted data, source credentials, identifiable information, or sensitive agreement details to the public repository. If a field is unsafe to share publicly, maintain it in an approved restricted site-local registry and publish only permitted metadata.

## 5. Cohort composition and clinical metadata availability

Capture distinct counts separately:

- `n_patients`: unique individuals within the defined cohort/release.
- `n_samples`: unique biological sample identifiers; repeated specimens/timepoints may increase this relative to `n_patients`.
- `n_assay_profiles`: optional count of assay profiles/data columns, if verified.
- `count_notes`: data freeze, exclusions, partial-release coverage, or counting assumptions.

Use `Unknown` or blank for unverified counts; **zero means a verified count of zero**.

Capture source-supported characteristics without forcing a cohort into one category if multiple apply. When several categories are present, use a consistent, documented multi-value convention or companion table:

| Field | Guidance |
| --- | --- |
| `cancer_types` | Source cancer types; mapping to OncoTree Level 1 is documented in the harmonization output. For multiple values, use a documented delimiter (e.g., semicolon) or a companion table; preserve original source labels. |
| `cancer_subtypes` | Source-supported subtypes or OncoTree Level 2 mappings; optional. |
| `treatment_regimens` | Source regimen labels or components; retain original drug names in approved source manifests. |
| `treatment_categories` | Harmonized categories when verified (e.g., PD-1/PD-L1, CTLA4, IO+combo, IO+chemo, IO+targeted). |
| `sampling_timepoints` | `Pre`, `On`, `Post` or source-specific terms, with ambiguity documented. |
| `clinical_age_available` | `Yes`, `No`, or `Unknown`. |
| `clinical_sex_available` | `Yes`, `No`, or `Unknown`. |
| `clinical_stage_available` | `Yes`, `No`, or `Unknown`. |
| `clinical_response_available` | `Yes`, `No`, or `Unknown`; specify endpoint type in notes. |
| `clinical_os_available` | `Yes`, `No`, or `Unknown`; does not imply valid paired time/event observations. |
| `clinical_pfs_available` | `Yes`, `No`, or `Unknown`; does not imply valid paired time/event observations. |
| `clinical_notes` | Relevant endpoint definitions, time origins, study restrictions, and caveats. |

**Availability vs readiness:** `Yes` indicates that relevant data have been identified, not that fields are sufficiently complete or comparable for pooled analysis. Readiness is assessed separately under [Quality Control](quality_control.md). Do not treat missing/unknown as `No`.

## 6. Molecular data inventory and annotations

For each cohort, capture the following registry-level molecular metadata. These availability indicators summarize the cohort; the corresponding sample-level fields in the [Data Dictionary](data_dictionary.md) are `rna`, `rna_info`, `dna`, and `dna_info`. Do not interpret missing or unverified data as `No`.

| Registry field | Description / recording rule |
| --- | --- |
| `rna_available` | `Yes`, `No`, or `Unknown`; RNA data availability at cohort level. |
| `dna_available` | `Yes`, `No`, or `Unknown`; DNA data availability at cohort level. |
| `other_assays` | Other documented modalities, if present; do not infer absence from unreported assays. |
| `source_data_level` | `Raw`, `Processed`, `Both`, or `Unknown`. |
| `assay_notes` | Available assay types, source processing descriptions, coverage, and relevant limitations. |

For each assay, document in a separate assay manifest where applicable:

| Property | Minimum documentation |
| --- | --- |
| Assay identity | Platform and assay type (RNA-seq, microarray, WES, WGS, SNV, CNA, etc.). |
| Data representation | Raw files, counts, TPM, normalized expression, segments, VCF/MAF, gene-level calls, etc. |
| Linkage | Assay sample identifier, biological sample identifier, cohort and patient relationship. |
| Reference genome | Assembly/build, when applicable (e.g., GRCh37/hg19 or GRCh38/hg38). |
| Gene annotation | Specific GENCODE version when known, or another documented source. |
| Processing | Pipeline name, version/commit, normalization, transformation, major parameters and QC results. |
| Coverage | Number of samples/profiles associated with the assay. |

### 6.1 GENCODE strategy

Document the project's working approach without retroactively assigning an unverified annotation to published data:

- **GENCODE v19** is the principal reference used for applicable published/processed cohorts where harmonization follows the established published-data workflow.
- **GENCODE v40** is the preferred annotation for cohorts with raw-data access that are reprocessed through the approved standardized workflow, when compatible with its reference genome and processing pipeline.
- **Explicitly reported source version:** retain and record the annotation release specified by the publication, data provider, or processing documentation.
- **Undocumented source annotation:** record `Unknown` until source evidence or identifier checks establish the actual release. Do not assert that published data used GENCODE v19 solely because it is a common project reference.

Record gene identifier conversions, genome-build changes, and relevant compatibility limitations. A GENCODE release alone does not establish which reference genome or quantification method was used. Preserve the source-reported release and validate compatibility before applying an alternative reference.

## 7. Versioning, quality review, and maintenance

Each registry record should be traceable to a source manifest or authorized provider record. When new data arrive:

1. Update the source release and retrieval/receipt information without overwriting the original provenance.
2. Recalculate and document counts from the appropriate grain (patient vs biological sample vs assay profile).
3. Confirm data-access classification and reuse/sharing constraints.
4. Reassess source field availability and molecular methods; record new or changed mappings.
5. Re-run relevant QC checks and record whether outputs remain comparable with the previous release.
6. Commit only permitted registry metadata and record the revision in version control.

A change in annotation, cohort definition, endpoint meaning, or source scope must be documented rather than silently replacing a prior interpretation. Keep cohort-specific mapping/QC decisions outside the summary table when they require detailed evidence.

## 8. Using the machine-readable registry

The **`config/cohort_registry_template.csv`** file defines a shared column layout. Copy it to an approved registry location and populate one row per cohort/release. The template contains **no real cohort data**. A populated registry may be shared through GitHub only when its entire contents are authorized for public release; otherwise, retain it in approved storage.

The registry is intended to support source inventories and descriptive cohort summaries. It is **not** a substitute for patient-level clinical metadata, assay manifests, source-level permissions checks, or executable QC.

For execution instructions, see [Usage](usage.md). For clinical target-variable definitions and source-to-target rules, see [Data Dictionary](data_dictionary.md). For validation and release checks, see [Quality Control](quality_control.md).

## Document history

| Version | Date | Status | Summary |
| --- | --- | --- | --- |
| 1.0 | November 20, 2026 | Active | MAR-40 cohort source inventory and registry conventions, access classifications, clinical/molecular availability, provenance, and cross-site reproducibility. |
