# MAR-40 Quality Control Framework

**Version:** 1.0  
**Scope:** Clinical, sample, treatment, outcome, and molecular data curated by MAR-40 collaborating teams at UHN, UCL, McGill, and other authorized sites  

## 1. Purpose and guiding principles

This document establishes **consistent, traceable quality-control (QC) procedures** for MAR-40 cohort curation and harmonization. Participating sites apply the same validation concepts and reporting conventions while processing restricted datasets inside authorized environments. The framework is **variable- and analysis-oriented**; conversion to OMOP is not required.

The goal is to distinguish three questions:

1. **Is the source documented?** Can the source, access permissions, file versions, record grain, and relevant clinical/molecular definitions be verified?
2. **Is the harmonization correct?** Are identifiers, values, units, transformations, annotation releases, and sample links consistent with the [Data Dictionary](data_dictionary.md)?
3. **Is the result fit for its intended analysis?** Are necessary values and endpoint/assay definitions sufficiently complete and comparable for the *specific* analysis being considered?

**Guiding principles**

- Preserve source records in approved storage; never overwrite original values during harmonization.
- Do not convert `NA`, `Unknown`, or an absent assessment into `No`, `0`, non-response, or a censored event.
- Do not resolve clinical or biological ambiguity by guessing. Record evidence and flag unresolved cases.
- Assess QC at the **correct record grain** (cohort, patient, sample, treatment episode, response assessment, or assay).
- Report counts **and denominators**. Distinguish samples from unique cohort-patients.
- QC status describes the readiness of a **particular output for a declared purpose**, not a blanket judgment of cohort quality.
- Keep local, restricted row-level issue files separate from shareable summaries; release only what data permissions allow.

## 2. QC stages and responsibilities

| Stage | Input | Main checks | Output |
|---|---|---|---|
| **A. Source QC** | Original source tables, files, publication/provider documentation | Provenance, permissions, file integrity, source schema, identifiers, assay definitions | Source manifest and source QC findings |
| **B. Post-harmonization QC** | Standardized clinical/sample/treatment tables and mapping log | Target schema, transformations, controlled values, missingness, consistency, endpoint definitions | Clinical QC and mapping-issue summaries |
| **C. Integration QC** | Molecular assay files, sample mappings, optional SE/MAE objects | Sample linkage, feature IDs, annotation/build, matrix dimensions, assay provenance | Molecular/integration QC summary |
| **D. Release review** | QC results, issues, manifests, outputs | Outstanding blocking findings, documented limitations, authorized destination | Cohort QC disposition and reviewer record |

**Responsibilities:** The contributing site's curator executes and documents checks. Site scientific/data leads review clinically important ambiguities and access restrictions. The MAR-40 harmonization team maintains shared rules and evaluates cross-cohort comparability. Changes to the shared rules follow the SOP's version-control process.

## 3. QC finding severity and cohort dispositions

**Finding severity** and **cohort disposition** are different fields and must not be conflated.

| Finding severity | Meaning | Typical action |
|---|---|---|
| `Error` | Violates a required integrity, identity, security, or validated data-contract rule | Correct or place the affected output on hold |
| `Review` | Scientific meaning, mapping, compatibility, or linkage is ambiguous | Investigate; document interpretation and reviewer decision |
| `Info` | Expected missingness, study limitation, or nonblocking deviation | Quantify and disclose; retain for analysis planning |

The final **cohort/output disposition** is one of:

- **Pass:** Applicable checks completed without unresolved blocking findings; essential provenance is available.
- **Pass with documented limitations:** Data are usable for a stated purpose but have nonblocking limitations that are recorded and reviewed.
- **Hold for review:** Blocking integrity/access problems or material unresolved mapping/endpoint/assay conflicts remain.

Do **not** set an arbitrary global missingness cutoff for all clinical variables. Relevance and acceptable completeness depend on the analysis, source design, and documented study requirements. Absence of a non-applicable or unreported optional field is not, by itself, a blocking error.

## 4. Source files, access, and provenance

| Rule ID | Check | Expected outcome | Default severity if violated |
|---|---|---|---|
| SRC-01 | Cohort recorded in the cohort registry and source manifest | Stable `cohort` identifier, source/provider, version, curator, and site | Error |
| SRC-02 | Access status verified | Confirm file-level `Public`, `Controlled access`, or `Private` classification and supporting permissions; cohort-level `Mixed` requires component-level classification and `Unknown` requires review | Error / Review |
| SRC-03 | Inputs readable and traceable | Filenames/locations, source revision, format, and checksums when permitted | Error |
| SRC-04 | Original data preserved | Source inputs not silently edited or overwritten | Error |
| SRC-05 | Schema and record grain documented | Each table identifies whether rows are patients, samples, visits, treatments, or assays | Review |
| SRC-06 | Approved execution and output destination | Restricted data remain in authorized institutional environments | Error |

Record missing source documentation explicitly. Do not assert a version, license, approval, or source interpretation that cannot be verified. A cohort-level `Mixed` access classification is acceptable only when each component has a verified access status; `Unknown` must be resolved before authorizing release.

## 5. Clinical and sample metadata QC

### 5.1 Identifiers and record structure

| Rule ID | Check | Expected outcome | Default severity |
|---|---|---|---|
| ID-01 | `cohort` and identifier availability | Nonmissing identifiers required for each table's record grain | Error |
| ID-02 | Patient keys | `(cohort, patientid)` uniquely identifies patient-level records; repeats are permitted in sample/longitudinal tables | Error for invalid grain |
| ID-03 | Sample keys | `(cohort, sampleid)` uniquely identifies sample-level records; multiple assays per sample are allowed in an assay-grain table | Error for invalid grain |
| ID-04 | Patient–sample linkage | Each sample resolves to a documented cohort-patient; missing or many-to-many relationships reviewed | Error / Review |
| ID-05 | Treatment and assessment episodes | Distinct treatments/timepoints are not accidentally collapsed or counted as independent patients | Review |
| ID-06 | Patient attributes across samples | Conflicting nonmissing age/sex/disease values are identified and assessed in context of timepoint and record meaning | Review |

Patient counts must be reported using **distinct `(cohort, patientid)` keys**. Do not assume `patientid` is globally unique across cohorts without verified identity linkage. Apparent differences in treatment, response, or disease status across visits or sampling timepoints are not automatically patient-level conflicts; review them at the correct assessment or treatment-episode grain.

### 5.2 Missingness and valid values

Assess missingness for every harmonized core variable at its correct grain. Use an explicit denominator: for example, `n_missing / n_patients` for a patient-level field and `n_missing / n_samples` for a sample-level field. When cohorts contain longitudinal assessments, report missingness by relevant timepoint/episode rather than only after flattening.

Recognize documented missing representations (e.g., blank, `NA`, `N/A`, `Unknown`, `Not recorded`), but retain distinguishable missingness reasons where known (`Not assessed`, `Not reported`, `Not applicable`, `Restricted`, `Unresolved`). **An observed negative value is not missing.**

| Rule ID | Check | Expected outcome | Default severity |
|---|---|---|---|
| CLN-01 | Target schema | Field names/types align with dictionary; approved aliases are mapped explicitly | Error / Review |
| CLN-02 | Missingness | Counts and denominators reported per cohort, variable, grain, and relevant timepoint | Info |
| CLN-03 | Demographics | Numeric age in years, plausible for study context; `sex` codes supported by source | Review |
| CLN-04 | Cancer classification | `cancer_type` aligned to documented OncoTree Level 1; Level 2 `cancer_subtype` only where supported | Review |
| CLN-05 | Stage/histology | Original definition and applicable classification/version retained | Review |
| CLN-06 | Treatment | Regimen/components/targets support standardized category; combination rules traceable | Review |
| CLN-07 | Sampling timing | `Pre`/`On`/`Post` only when source chronology or definition supports assignment | Review |
| CLN-08 | Access metadata | Canonical `access_type` documented; legacy `access type` mapped through explicit adapter | Review |

Unrecognized values must be reported, not silently discarded, mapped to `Other`, or converted to missing. Use `Other` only where the dictionary and source evidence support that designation.

### 5.3 Response and survival outcomes

| Rule ID | Check | Expected outcome | Default severity |
|---|---|---|---|
| OUT-01 | RECIST response | `recist` values/assessment criteria (e.g., CR/PR/SD/PD or evaluability status) documented with criteria version/timepoint | Review |
| OUT-02 | Binary response | `response` definition documented; not automatically derived from RECIST or clinical benefit | Review |
| OUT-03 | OS/PFS time | Nonnegative numeric values in **months**, with source unit and conversion recorded | Error / Review |
| OUT-04 | Event indicator | `event_occurred_os` / `event_occurred_pfs` explicitly recoded to verified `1 = event`, `0 = censored` | Error / Review |
| OUT-05 | Time/event pairing | Count records with both valid duration and event indicator for each endpoint | Info / Review |
| OUT-06 | Endpoint definition | Time origin, event definition, censoring and follow-up context documented; incompatible definitions flagged | Review |
| OUT-07 | Longitudinal interpretation | Ensure response/survival endpoints link to appropriate patient and, if applicable, treatment episode | Review |

**Two distinct metrics must be reported:**

- **Metadata availability:** A cohort has OS/PFS metadata if at least one patient has a nonmissing duration **or** event field. This is the rule used in the existing clinical-availability heatmap.
- **Record-level endpoint completeness:** A patient/episode has complete OS/PFS fields only when a valid duration **and** its corresponding verified event indicator are present. **Analysis readiness requires additional checks** for endpoint meaning, origin, and suitability of the analysis population.

Avoid treating a cohort's observed median time as Kaplan–Meier median survival or median follow-up without the relevant statistical method.

## 6. Molecular assay and annotation QC

Core molecular metadata QC uses four fields: `rna` and `dna` report assay availability (`Yes`, `No`, or missing), while `rna_info` and `dna_info` describe the technology and processing information when available. A missing assay is not automatically a failed QC check, and `No` must be source-supported. Rules MOL-02 through MOL-08 apply only to relevant molecular data and do not add required core dictionary fields.

| Rule ID | Check | Expected outcome | Default severity |
|---|---|---|---|
| MOL-01 | Assay inventory | RNA/DNA presence (`rna`, `dna`) separate from assay description (`rna_info`, `dna_info`) | Review |
| MOL-02 | Assay identity | Sample IDs and assay IDs traceable to approved sample metadata | Error / Review |
| MOL-03 | Molecular format and scale | Counts/TPM/microarray/variants/CNA data distinguished; normalization and transformations documented | Review |
| MOL-04 | Reference and gene annotations | Genome build, gene ID scheme, and GENCODE or other annotation releases recorded or explicitly `Unknown` | Review |
| MOL-05 | Feature and sample integrity | Matrix dimensions, duplicate feature/sample IDs, missing rows/columns, feature metadata and sample names checked | Error / Review |
| MOL-06 | Cross-assay compatibility | Build/identifier/version differences explicitly reconciled; no implicit gene-ID or genome-build mixing | Review |
| MOL-07 | Mutation/CNA representations | Variant type, reference build, caller/filter versions, CNA representation and binary-call rules traceable | Review |
| MOL-08 | SE/MAE validation where used | `assay` dimensions align with `rowData`/`colData`; `sampleMap` maps assays to correct cohort-patients | Error / Review |

**GENCODE policy:** For applicable published processed datasets, **GENCODE v19** is the historical MAR-40 harmonization reference; **do not assign GENCODE v19 when the true source annotation is unverified**. For available raw datasets that are reprocessed using MAR-40 standardized pipelines, prefer **GENCODE v40** with its compatible reference genome. Where a publication/provider specifies another release, retain the documented source version. Track the source release, genome build, pipeline, and any conversion or feature remapping. Different gene annotations or expression scales are not automatically comparable.

For microarrays, retain the source platform, normalization, probe mapping and annotation release; do not describe normalized microarray signals as TPM. Clinical-only cohorts do not need an artificial assay or MAE object.

## 7. Mapping quality and cross-cohort comparability

The dictionary uses **`Direct`**, **`Conditional`**, **`Needs review`**, and **`Unmapped`** as mapping statuses. A status describes a **mapping decision**; it is not the same as a QC severity or a cohort disposition.

| Rule ID | Check | Expected outcome | Default severity |
|---|---|---|---|
| MAP-01 | Source-to-target traceability | Source name, original value/code, grain, definition, rule ID and target field retained | Error / Review |
| MAP-02 | Verified transformations | Recode, merge, join, unit conversion or derived value documented and reproducible | Error / Review |
| MAP-03 | Unresolved mappings | `Needs review` / `Unmapped` values retained in issue log and excluded from unsupported derived interpretations | Review |
| MAP-04 | Controlled vocabulary versioning | OncoTree, treatment mappings, gene annotation and other resource releases recorded | Review |
| MAP-05 | Cohort comparability | Relevant endpoint definition, treatment context, assay scale, genome build and sampling design assessed for each analysis | Review |
| MAP-06 | Rule consistency | Common transformations have identical versions and semantics across contributing sites | Review |

Cross-cohort comparability should be evaluated for **the intended scientific use case**. A variable can be syntactically standardized but remain biologically or clinically incomparable; the issue must be visible to analysts.

## 8. Standard QC reports and output contract

Each cohort should generate or document the following artifacts **when applicable and permitted**. These are recommended names consistent with the [SOP](data_curation_SOP.md); a shareable aggregate report can be substituted for restricted row-level outputs.

```text
<cohort_id>/
├── source_manifest.tsv          # Sources, access, versions and authorized paths
├── mapping_log.tsv              # Variable-/value-level mapping rules and decisions
├── qc_summary.tsv              # One row per QC check, with findings and denominators
├── unresolved_issues.tsv        # Issue details and decisions, in approved storage
├── assay_manifest.tsv           # Assay types and processing/annotation provenance, if present
└── run_manifest.txt             # Code/environment/input provenance
```

These filenames define the **recommended full QC reporting contract**; they are not all outputs of the currently implemented workflow. The [Snakemake cohort visualization workflow](visualization_workflow.md) currently generates descriptive figures and reports, including `cohort_summary.csv`, `cohort_variable_missingness.csv`, and `patient_level_conflicts.csv`. Those outputs support cohort review but do not implement all rule IDs or replace source-level, molecular, and endpoint-specific QC.

Additional recommended QC views may be produced from the same checks: `missingness_summary.tsv`, `patient_sample_validation.tsv`, `endpoint_completeness.tsv`, and `molecular_qc_summary.tsv`. Keep one canonical issue log, rather than conflicting copies with different statuses.

### 8.1 `qc_summary.tsv` columns

| Column | Meaning |
|---|---|
| `cohort` | Cohort identifier |
| `qc_stage` | `Source`, `Harmonized`, `Integration`, or `Release` |
| `rule_id` | Stable identifier defined in this document or a versioned rule configuration |
| `domain` | Identity, clinical, outcome, molecular, provenance, mapping, etc. |
| `record_grain` | Cohort, patient, sample, assay, episode, etc. |
| `n_checked` | Number of eligible records checked |
| `n_flagged` | Number of records or instances flagged for this check |
| `severity` | `Error`, `Review`, or `Info` |
| `check_status` | `Pass`, `Flagged`, or `Not applicable` |
| `description` | Concise finding/interpretation |
| `issue_log_ref` | Local pointer to issue record(s), where permitted |
| `rule_version` | QC-rule implementation version |
| `run_id` | Identifier linking the result to the run manifest |

For rules that apply once per cohort or file, use the appropriate grain and denominator; do not report percentages without explaining the checked population. A **flagged** finding does not necessarily mean the entire cohort is on hold.

### 8.2 `unresolved_issues.tsv` columns

Recommended fields: `issue_id`, `cohort`, `rule_id`, `affected_grain`, `affected_record_key` (local/restricted where needed), `description`, `severity`, `mapping_status` (if relevant), `evidence`, `proposed_action`, `owner`, `reviewer`, `review_date`, `resolution`, `issue_status`, `run_id`.

Store patient-level identifiers or sensitive source values only in approved storage. Share sanitized aggregates or non-identifying issue summaries when authorized.

### 8.3 `run_manifest.txt` minimum content

Record input source IDs and versions/checksums where permitted; workflow/script and Git commit; data dictionary and mapping versions; environment lockfile or package versions; configuration, run date, site/curator, authorized output path, and QC rule version. Re-running against the same permitted inputs and versions should regenerate the QC outputs without manual edits to the final tables.

## 9. Review and release procedure

1. **Execute** the applicable QC checks on source, harmonized, and integrated data, as supported by the cohort's modalities.
2. **Inspect** every `Error` and clinically material `Review` finding; document fixes, scientific interpretation, or explicit limitations.
3. **Re-run** affected checks after code, mapping, or data corrections; preserve the run/version history.
4. **Assign a disposition** (`Pass`, `Pass with documented limitations`, or `Hold for review`) for the specific output and intended analysis.
5. **Record the designated reviewer and decision**, including the output/dataset version, intended use, review date, unresolved limitations, and any restrictions; confirm that sharing and destination are authorized before any cross-site release.
6. **Release only approved outputs** with their manifests and permissible QC summaries.

A held cohort need not be discarded: the relevant issue may affect only a particular assay or endpoint. The release decision should specify what is usable, restricted, pending review, or excluded from a stated analysis.

### Curation and harmonization QC checklist

- [ ] Source identity, provenance, access classification and permissions documented.
- [ ] Required identifiers valid at the correct grain; patient–sample links checked.
- [ ] Harmonized fields validated against the versioned dictionary.
- [ ] OncoTree cancer classification and treatment-group mappings reviewed.
- [ ] Response and OS/PFS definitions, units, event coding and completeness checked.
- [ ] RNA/DNA assay metadata, GENCODE/source annotation, genome build and processing provenance reviewed where applicable.
- [ ] SE/MAE and `sampleMap` validated if created.
- [ ] Missingness and mapping issues reported with counts, denominators and dispositions.
- [ ] QC outputs and run manifest saved in approved storage, with the correct version identifiers.
- [ ] Relevant site reviewer decision and permitted release destination documented.

## 10. Maintenance and change control

The MAR-40 harmonization team maintains this framework alongside the [SOP](data_curation_SOP.md) and [Data Dictionary](data_dictionary.md). New validation rules must include a stable `rule_id`, objective, input grain, expected result, severity, implementation version, and examples/test cases. Changes that alter clinical interpretations, mapping categories, endpoint comparability or assay processing require review by the relevant scientific/data leads.

Record changes in Git; preserve enough version information to reproduce earlier QC results. If a rule change affects previously released cohorts, assess whether outputs should be regenerated and document that decision. This document defines the **QC specification**; executable implementations and configuration are maintained with the workflows described in [Usage](usage.md).

### Document history

| Version | Date | Status | Description |
|---|---|---|---|
| 1.0 | 2026-11-20 | Active | MAR-40 cross-site QC specification aligned with Data Curation SOP v1.0 and Data Dictionary v1.0; editorial clarifications to access handling, molecular metadata, reporting scope, and review decisions. |
