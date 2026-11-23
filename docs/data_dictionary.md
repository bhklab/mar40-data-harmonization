# MAR-40 Data Dictionary and Harmonization Guide

**Version:** 1.0  

**Scope:** Clinical, sample, treatment, outcome, and molecular metadata curated by MAR-40 teams at UHN, UCL, McGill, and other authorized collaborating sites  

## 1. Purpose and principles

This dictionary defines a **focused MAR-40 research data model**, not a conversion to OMOP. Its purpose is to support interpretable, reproducible harmonization of immuno-oncology datasets with different study designs, treatment regimens, response measures, and molecular assays. Map **scientifically relevant variables**, not every field in a source database.

Use the same target field names across collaborating institutions, but **do not assume fields with the same name have the same meaning**. Each cohort must document original terminology, definitions, units, time origins, preprocessing, and any transformations. Preserve original records in their authorized storage environments; keep the harmonized version and mapping decisions traceable to those records.

The common data model and overall approach are aligned with the MAR-40 SOP v1.0. **Individual source-to-target mappings still require evidence-based curation**; values or conventions presented as examples below are not approvals to infer missing information.

**Key conventions**

- **Grain / level:** The entity represented by each record (cohort, patient, sample, treatment episode, response assessment, assay). Do not flatten repeated visits, treatment courses, or samples without a documented aggregation rule.
- **Requiredness:** **Identifier** = required for records at the specified grain; **Core** = the harmonized column should be represented, but its value can be missing if unavailable; **Conditional** = required when that data type or analysis is present; **Extended** = enriches interpretation, where reported.
- **Patient identity:** Use `(cohort, patientid)` as the patient key unless a validated linkage shows that patients are identical across cohorts. Sample keys use `(cohort, sampleid)`.
- **Missingness:** Blank/`NA` denotes an unobserved harmonized value. `No` or `0` is a negative value **only if explicitly supported by the source**, never a substitute for missing data. Capture the reason (`Not reported`, `Not assessed`, `Not applicable`, `Restricted`, `Unresolved`) in a supplemental missingness/issue log when known.
- **Source fidelity:** Retain the original source field/value, units, record level, and source evidence; avoid unsupported inference.
- **Data governance:** Schema, scripts, synthetic examples, and permitted aggregate summaries may reside in GitHub; controlled/private patient-level data must remain in authorized environments.

## 2. Recommended logical data structure

| Table or object | Record grain | Identifier / link | Purpose |
|---|---|---|---|
| Cohort registry | One row per cohort | `cohort` | Source, permissions, modality coverage, dataset versions |
| Clinical metadata | One row per `(cohort, patientid)` or documented patient-treatment record | `cohort`, `patientid` | Baseline demographics, cancer characterization, outcomes |
| Sample metadata | One row per `(cohort, sampleid)` | `cohort`, `sampleid`, `patientid` | Specimen, sampling time, patient connection |
| Treatment metadata | One row per documented treatment episode | `cohort`, `patientid`, `treatmentid` when available | Regimen, components, targets, treatment setting |
| Outcome assessments | One row per documented assessment/episode | Patient and treatment linkage plus assessment index/time | RECIST/other outcome and assessment provenance |
| Assay inventory / molecular objects | One row per assay-sample combination, or appropriate MAE object | `cohort`, `sampleid`, `assay_id` | RNA/DNA modality, processing methods, features and measurements |
| Mapping and QC logs | One row per transformation, decision, or issue | Cohort ID, source field, mapping rule/issue ID | Auditability across sites |

A **single sample-level flat CSV is an acceptable descriptive export** if it maintains correct patient/sample links; it is not the canonical representation of longitudinal treatment, response, or molecular measurements. The visualization script may use such a flattened export.

## 3. Core clinical and sample variables

Columns below are **target MAR-40 names**. `String` means a character value; identifiers should not be coerced to numbers (leading zeros may matter). Example categorical values indicate the expected format, not permission to guess a value.

| Domain | Target field | Level | Requiredness | Definition and permitted format | Harmonization / validation guidance |
|---|---|---|---|---|---|
| Identity | `cohort` | Cohort / all records | Identifier | Stable cohort ID; string | Must match cohort registry; site-specific naming without collisions |
| Identity | `patientid` | Patient and linked records | Identifier | Pseudonymous patient ID; string | Unique **within** cohort; preserve cross-file linkage |
| Identity | `sampleid` | Sample | Identifier | Unique sample ID; string | May be repeated across assay rows only when grain requires it |
| Identity | `tissueid` | Specimen, if available | Conditional | Tissue/specimen identifier; string | Distinguish biological specimen from aliquot/assay sample |
| Identity | `treatmentid` | Treatment episode | Conditional | Treatment identifier; string | Required to distinguish multiple therapy episodes when source provides them |
| Demographics | `age` | Patient / baseline | Core | Numeric age in **years** | Record `age_reference` and original age units/timepoint; do not treat age at diagnosis as age at treatment without evidence |
| Demographics | `sex` | Patient | Core | Source-recorded `F`, `M`, other supported value, or missing | Map only categories substantiated by the original source; keep original value in mapping log |
| Disease | `cancer_type` | Patient or tumor | Core | OncoTree **Level 1** (broad cancer type) | Document OncoTree release and source label; never map histological subtype to a broad category by unsupported guesswork |
| Disease | `cancer_subtype` | Patient or tumor | Conditional | OncoTree **Level 2** when supported | Leave missing if subtype cannot be established; retain original terminology |
| Disease | `histo` | Patient / tumor | Extended | Histology as reported; string | Record histology system/code when available; keep provenance |
| Disease | `stage` | Patient / assessment | Core | Source stage or valid harmonized stage; string | Preserve stage system, edition, assessment date and whether primary/metastatic; do not merge incompatible staging systems |
| Treatment | `treatment` | Treatment episode | Core | Broad treatment group, as defined in §4 | Preserve original regimen and constituent drug names; define rule for combinations |
| Treatment | `target` | Treatment episode | Core | Target(s), e.g., `PD-1`, `PD-L1`, `CTLA-4` | Targets need not be unique; preserve multi-target combinations separately where possible |
| Treatment | `regimen` | Treatment episode | Conditional | Exact source regimen/drugs; string | Do not replace regimen with broad `treatment` class |
| Treatment | `treatment_setting` | Treatment episode | Extended | Original and (when possible) standardized disease/treatment setting | Preserve neoadjuvant, adjuvant, metastatic, etc. with evidence |
| Sample | `sample_timing` | Sample | Core | `Pre`, `On`, `Post`, missing | Relative to **which treatment episode?** Document source time and reference event; do not force ambiguous timepoints |
| Sample | `sample_type` | Sample | Extended | Biological material (tumor tissue, plasma, PBMC, etc.) | Record source material and collection method |
| Sample | `sample_source` | Sample | Conditional | `Primary`, `Metastatic`, or original location/status if supported | Preserve anatomical site separately; not interchangeable with timing |
| Sample | `specimen_site` | Sample | Extended | Anatomic collection site, original/standardized | Do not infer site from disease type |
| Outcome | `recist` | Assessment / episode | Core | `CR`, `PR`, `SD`, `PD`, `NE` where criteria support them | Confirm RECIST or other assessment system/version, assessor and timepoint; `NE` is not `PD` |
| Outcome | `response` | Assessment / episode | Core | `R`, `NR`, missing | Binary response requires **source-supported definition**; do not automatically infer from `recist` |
| Survival | `survival_time_os` | Patient / episode | Core | Numeric OS duration, **months** | Confirm origin, endpoint and conversion from source units; nonnegative |
| Survival | `event_occurred_os` | Patient / episode | Core | `1` death event, `0` censored, missing | Verify original event convention and pairing with the time value |
| Survival | `survival_time_pfs` | Patient / episode | Core | Numeric PFS duration, **months** | Confirm progression/death definition, origin, and censoring; nonnegative |
| Survival | `event_occurred_pfs` | Patient / episode | Core | `1` event, `0` censored, missing | Verify that original 0/1 meaning and endpoint definition align |
| Survival | `survival_unit` | Cohort / outcome | Conditional | Original and/or harmonized duration units | Harmonized durations use months; preserve original units and conversion rule |
| Provenance | `data_source` | Cohort | Conditional | Accession, DOI, publication, or authorized internal reference | Do not record credentials or restricted storage locations in public files |
| Provenance | `access_type` | Cohort | Core | `Public`, `Controlled access`, `Private` | Access status reflects permissions, not dataset quality; mixed status needs investigation or per-file classification |
| Provenance | `source_version` | Cohort / file | Conditional | Release/date/checksum/version; string | Required for reproducible provenance where available |

### 3.1 Distinguishing clinical entities

- One patient may have multiple samples, sequencing assays, treatment regimens and response assessments.
- Patient-level response or stage summaries need an **explicit aggregation/selection rule** (for example, best overall response under a specified criteria and window); do not silently select a convenient record.
- If a longitudinal schema is not yet implemented, maintain companion tables or manifest entries describing the original grain and any aggregation applied to make a flat export.

## 4. Treatment and response definitions

### 4.1 Treatment classification

The SOP recognizes the main MAR-40 immunotherapy groupings. Preserve at least three distinct concepts: **source regimen**, **drug/immune target**, and **harmonized treatment group**.

| Treatment group | Interpretation | Key caution |
|---|---|---|
| `PD-(L)1` | PD-1 or PD-L1-directed therapy when classified as a single-target group | Do not label a multi-agent regimen as monotherapy simply because it includes PD-(L)1 blockade |
| `CTLA4` | CTLA-4-directed single-target therapy | Preserve exact drug and mechanism |
| `IO+combo` | Immunotherapy combination not represented by a more specific selected category | Specify which components qualify; avoid overlap with `IO+chemo` or `IO+targeted` |
| `IO+chemo` | Immunotherapy plus chemotherapy | Confirm concurrent/combined therapy and study definition |
| `IO+targeted` | Immunotherapy plus targeted therapy | Confirm exact combination and drug targets |
| `Other` | Documented regimen outside defined groups | Preserve unmodified regimen |

**Implementation note:** A treatment classification must not rely on a substring match alone. Multi-component regimens require a versioned precedence rule **or** a structured multi-label representation. If a cohort does not supply the information needed, flag the classification for review.

### 4.2 Response

`recist` and `response` are separate fields. For `recist`, document assessment criteria (RECIST v1.1, iRECIST or other), assessor, timepoint, and whether the result is **best overall response**. For `response`, record the cohort's responder definition and its relationship, if any, to RECIST. Clinical benefit, objective response, pathological response, and investigator-assessed response **must not automatically be treated as equivalent**.

### 4.3 Survival

Use `survival_time_os` and `survival_time_pfs` in months, with original units and transformation documented. A verified event coding is `1 = event; 0 = censored`; if the source uses the reverse convention, document the recoding. Preserve time origin (`diagnosis`, `treatment start`, `randomization`, etc.), event definition, and censoring rules in the cohort-level endpoint dictionary or mapping record. **Availability of at least one OS/PFS field does not mean the cohort is ready for survival analysis**; each record requires a valid paired time/event measurement and a compatible endpoint definition.

## 5. Molecular variables and assay documentation

Molecular metadata should distinguish **assay presence**, **modality**, **measurement scale**, and **processing provenance**. A `Yes` value is not an RNA-seq method; a `No` value must not represent unavailable information without evidence.

| Target field | Level | Requiredness | Description and documentation |
|---|---|---|---|
| `rna` | Sample | Core | Availability status `Yes`, `No`, or missing; `No` only when explicitly assessed absent |
| `rna_info` | Sample / assay | Conditional | Source RNA technology/platform and processing description; use structured assay manifest for full details |
| `dna` | Sample | Core | Availability status `Yes`, `No`, or missing |
| `dna_info` | Sample / assay | Conditional | DNA modality (WES/WGS/panel/etc.) and processing summary |
| `assay_id` | Assay | Conditional | Identifier linking assay entry with sample |
| `assay_type` | Assay | Conditional | RNA-seq, microarray, WES, WGS, panel, SNV, CNA, etc. |
| `measurement_type` | Assay | Conditional | Counts, TPM, normalized microarray signal, variant calls, segments, gene-level CNA, etc. |
| `normalization` | Assay | Conditional | Algorithm, parameters, transformations and pseudocount (if any) |
| `reference_genome` | Assay | Conditional | Genome assembly, e.g. GRCh37/hg19 or GRCh38/hg38, **verified from source/pipeline** |
| `gencode_version` | RNA assay | Conditional | Verified GENCODE release; see §5.1 |
| `gene_id_type` | Assay | Conditional | Ensembl gene ID, gene symbol, probe ID, etc.; record version suffix policy |
| `annotation_version` | Assay | Conditional | Reference/annotation release, including non-GENCODE sources as applicable |
| `processing_pipeline` | Assay | Conditional | Tool/workflow name, version, reference and parameters |
| `processing_source` | Assay | Conditional | Published processed data, provided processed data, or MAR-40 raw-data reprocessing |
| `feature_mapping_version` | Assay | Conditional | Gene/probe mapping resource and release |
| `assay_qc_status` | Assay | Conditional | Pass / limitations / hold, as determined by QC procedure |

### 5.1 GENCODE annotation strategy

MAR-40 uses the following **source-aware strategy**:

1. **Published processed datasets:** **GENCODE v19** is the historical harmonization reference where applicable; however, **do not assign GENCODE v19 to a dataset solely because its true annotation is unknown**. If the publication/provider specifies a different release, retain the documented release. If not verifiable, record `Unknown` in assay provenance and flag for review.

2. **Raw datasets available for standardized reprocessing:** Prefer **GENCODE v40**, with its compatible genome build and an explicitly documented quantification pipeline.

3. **Source-declared versions:** When a publication or data provider identifies an annotation release, preserve that information even if it differs from GENCODE v19 or GENCODE v40.

Record GENCODE release (e.g., GENCODE v19 or GENCODE v40), genome build, gene ID type, quantification method, source reference and all conversions. **Do not treat different GENCODE releases or builds as interchangeable**, and do not label legacy expression measurements as reprocessed using GENCODE v40 unless actually reprocessed with that annotation.

### 5.2 Multi-assay integration

When appropriate, build `SummarizedExperiment`, `RangedSummarizedExperiment`, or `MultiAssayExperiment` objects. Validate feature and sample dimensions, `rowData`, `colData`, and the patient/sample relationships represented by `sampleMap`. A clinical-only cohort can be curated without generating a fictitious molecular assay.

## 6. Mapping rules and statuses

MAR-40 mapping is **key-variable, meaning-driven harmonization**. It does not require OMOP concept IDs or conversion to OMOP database tables.

| Mapping status | Definition | Example / action |
|---|---|---|
| `Direct` | Equivalent meaning, grain, and units; rename or copy | `patient_id` → `patientid`, after ID checks |
| `Conditional` | Meaning is compatible after verified recoding, transformation, or unit conversion | Source `OS_days` → months with verified origin and conversion |
| `Needs review` | Source definition, endpoint, timepoint, or clinical equivalence is uncertain | `best_response` → `recist` pending criteria check |
| `Unmapped` | No defensible target equivalence | `clinical_benefit` must not be silently assigned `response` |

Recommended mapping-log columns:

`cohort`, `source_file`, `source_variable`, `source_value_or_code`, `source_definition`, `source_grain`, `source_unit`, `target_variable`, `target_value_or_code`, `transformation`, `rule_id`, `mapping_status`, `evidence`, `reviewer`, `review_date`, `mapping_version`, `notes`.

A mapping record may be **variable-level** (source column → target column) or **value-level** (source category → standardized category). Where a variable needs both, record both. Keep restricted source values in approved storage; public repository mapping examples should be synthetic or non-sensitive.

### 6.1 Illustrative mappings (not blanket approvals)

| Source field/value | MAR-40 target | Rule and necessary verification | Status |
|---|---|---|---|
| `patient_id` | `patientid` | Preserve as string; confirm cohort-scoped uniqueness | Direct |
| `tumor_type = Skin melanoma` | `cancer_type` | Map to OncoTree Level 1, record vocabulary release and original term | Conditional |
| `best_overall_response = PR` | `recist` | Confirm assessment criteria/version and definition | Needs review until verified |
| `sex = Female` | `sex = F` | Only after confirming source-recorded category | Conditional |
| `OS_days` | `survival_time_os` | Verify origin, censoring and unit conversion; do not copy numeric days into month field | Conditional |
| `clinical_benefit = Yes` | `response` | Not necessarily objective response; retain source meaning | Unmapped pending scientific justification |

### 6.2 OncoTree and tumor taxonomy

Harmonize `cancer_type` to the agreed **OncoTree Level 1** classification and populate `cancer_subtype` from **Level 2** only when a supported mapping is available. Preserve the original histology/tumor label, code and OncoTree version. Distinguish tumor primary, specimen site and metastatic status; escalate ambiguous diagnoses or multiple primaries.

## 7. Quality control and completeness reporting

Follow [Quality Control](quality_control.md) and the [SOP](data_curation_SOP.md). At minimum, evaluate:

| QC area | Core checks |
|---|---|
| Identifiers | Missing/duplicate patient or sample IDs, uniqueness in correct scope, patient-to-sample linkage |
| Grain | Patient-level variables repeated consistently; longitudinal assessments not inadvertently collapsed |
| Allowed categories | Valid treatment/access/response codes; list all unmapped source values |
| Disease mapping | Supported OncoTree Level 1/2, original labels and release preserved |
| Outcomes | Valid nonnegative times, verified event coding, paired time/event fields, time origin/censoring documented |
| Molecular | Assay availability vs type, gene IDs, reference build, annotation release, dimensions and sample mappings |
| Missingness | Report missingness by cohort, variable, patient/sample and, when relevant, timepoint |
| Reproducibility | Source versions, mapping log, code commit, environment, parameters, QC decisions |
| Data access | Cohort and source-file permissions, permitted destinations and sharing limitations |

**Completeness ≠ comparability.** For example, a cohort with a populated `response` column may still be incompatible with another cohort if response definitions differ. A heatmap cell of “Yes” signifies that at least one value was observed, not that all records are complete or analytically comparable.

## 8. Example export conventions and compatibility

The current MAR-40 synthetic sample-level visualization workflow uses fields including `cohort`, `patientid`, `sampleid`, `cancer_type`, `histo`, `stage`, `age`, `sex`, `treatment`, `target`, `sample_timing`, `recist`, `response`, `survival_time_os`, `event_occurred_os`, `survival_time_pfs`, `event_occurred_pfs`, `rna`, and `dna`. Some versions also include `regimen`, `sample_source`, and a source column named **`access type`**.

**Naming policy:** Use **`access_type`** as the canonical dictionary field; accept legacy `access type` as an input alias through an explicit mapping/adapter. Do not silently change script dependencies. Similarly, distinguish `rna` / `dna` **availability** from `rna_info` / `dna_info` **assay descriptions**. Maintain a schema version for each exported dataset.

Suggested locally generated cohort outputs (subject to source permissions):

```text

<cohort_id>/

  source_manifest.tsv

  mapping_log.tsv

  clinical_harmonized.csv

  sample_metadata.csv

  assay_manifest.tsv

  qc_summary.tsv

  unresolved_issues.tsv

  run_manifest.txt

```

The files and layout above describe an **output contract to implement**, not a claim that every file currently exists. Data protection and permitted sharing take precedence over repository convenience.

## 9. Cross-site review and maintenance

The **MAR-40 harmonization team** maintains this dictionary together with the SOP and executable QC/mapping configuration. A contributing site documents source-specific details and flags uncertainties. Material changes (e.g., endpoint definitions, treatment grouping, OncoTree release, GENCODE processing, access conventions) should be reviewed with the relevant scientific/data leads and recorded in Git history before adoption across sites.

When updating a field, record: **what changed, why, affected cohorts/analyses, version, reviewer, date and required reprocessing**. Maintain backward-compatible mappings where feasible. Do not silently replace historical values in already released outputs.
