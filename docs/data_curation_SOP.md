# MAR-40 Data Curation and Harmonization SOP

**Version:** 1.0

**Scope:** Participating MAR-40 teams curating clinical and molecular immuno-oncology cohorts

**Document owner(s):** Farnoosh Abbas Aghababazadeh

**Related documents:** [Clinical metadata](clinical_metadata_standardization.md) · [Molecular standardization](molecular_data_standardization.md) · [Data dictionary](data_dictionary.md) · [Data sources](data_sources.md) · [Quality control](quality_control.md) · [Usage](usage.md)

## 1. Purpose and expected outcome

Establish a transparent, reproducible procedure for acquiring, curating, harmonizing, validating, and documenting clinical and molecular data contributed to MAR-40. Apply common data definitions across institutions while retaining the meaning and provenance of the original source records.

At the end of curation, each cohort should have, **where the source data permit**:

- A versioned source inventory and provenance record.
- Harmonized patient- and/or sample-level clinical metadata with documented identifiers.
- Standardized treatment, disease, response, survival, and assay descriptors.
- Processed molecular data with documented units, reference annotations, and processing methods.
- An explicit linkage between clinical records and molecular samples; an MAE object when appropriate.
- A quality-control (QC) report, mapping log, unresolved-issues register, and reproducibility manifest.

**Principle:** Do not invent missing clinical measurements, infer unsupported mappings, or silently discard records. An absent or unverified variable is not a negative observation.

## 2. Roles, accountability, and data stewardship

| Role | Responsibility |
| --- | --- |
| Contributing site / cohort curator | Identify approved sources, perform source-level curation, record provenance and mapping decisions, run QC. |
| Site scientific/data lead | Review clinical meaning, data-access constraints, and flagged ambiguities; approve site-specific submissions. |
| MAR-40 harmonization team | Maintain shared schemas, mapping rules, versioned workflows, and cross-site comparability checks. |
| Designated scientific reviewer | Resolve decisions that change endpoint meaning, response definitions, tumor taxonomy, or assay comparability. |

**Review rule:** A curator must not independently resolve a clinically consequential ambiguity by guesswork. Record it as **Needs review** and escalate to the site's designated reviewer. Maintain a change log for decisions applied across cohorts.

### 2.1 Data protection and permitted sharing

- Classify data as **Public**, **Controlled access**, or **Private**, based on actual source permissions and institutional agreements. These labels describe access arrangements, not data completeness.
- Use only approved institutional environments for controlled/private patient-level information. Do not commit restricted source data, credentials, or direct identifiers to GitHub.
- Keep a shareable repository containing code, documentation, mappings permitted for distribution, test fixtures, and approved synthetic examples.
- Before sharing any outputs across borders or organizations, confirm the applicable ethics approval, data-transfer agreement, institutional policy, and export permissions. Technical reproducibility does not itself grant permission to share data.
- Where data cannot move between sites, execute the approved workflow locally and share only explicitly permitted metadata, reports, or aggregate results.

## 3. Overall workflow

1. **Register a cohort and verify access.** Establish source, citation, scope, permissions, and local contact.
2. **Inventory source files.** Preserve raw inputs; record file versions, assays, units, and identifiers.
3. **Curate clinical metadata.** Standardize identifiers, demographics, disease, therapy, response, and survival fields.
4. **Process or import molecular profiles.** Document RNA and DNA methods and preserve assay-specific information.
5. **Harmonize annotations and vocabularies.** Apply versioned mappings for tumor types, drugs, endpoints, and features.
6. **Integrate sample-to-patient relationships.** Produce interoperable tables and MAE components, when applicable.
7. **Perform automated QC and scientific review.** Resolve or explicitly flag inconsistencies.
8. **Release curated outputs.** Version outputs and record input provenance, code commit, software environment, and reviewer decisions.

## 4. Cohort registration and source inventory

Create one entry per cohort in the registry described in [Data sources](data_sources.md). Record at least:

| Information | Expected record |
| --- | --- |
| Cohort identifier | Stable project-specific cohort ID; avoid naming collisions across sites. |
| Source | Publication/DOI, accession, study documentation, provider, or approved local location. |
| Site and curator | Contributing organization, responsible curator, contact or team. |
| Access status | Public / Controlled access / Private, with permission or agreement reference. |
| Study design | Trial/observational; treatment arms and timepoints if documented. |
| Data availability | Clinical, RNA, SNV, CNA, other; raw vs processed; counts and formats. |
| Source revision | Download/release date, original filename, checksum where permitted. |
| Use restrictions | Distribution, reuse, location, and retention restrictions. |

**Completion check:** The origin and access status of every input file are traceable. Retain the original data as received; do not overwrite `rawdata` during standardization.

## 5. Clinical metadata curation

### 5.1 Define record granularity and identifiers

Distinguish **patient**, **specimen/sample**, **assay**, **treatment episode**, and **timepoint**. Repeated samples from one patient must not be counted as distinct patients. Use site-appropriate pseudonymous identifiers and preserve an approved, protected linkage when necessary.

- `patientid`: stable within the defined cohort and uniquely linked to the relevant patient.
- `sampleid`: stable sample identifier; one patient can have multiple sample IDs.
- `treatmentid`: treatment regimen identifier when supported by the source.
- `sample_timing`: documented pretreatment/on-treatment/post-treatment or other timepoint classification; retain original dates/labels in controlled source records if permitted.
- When patient IDs can overlap between cohorts, identify a patient by **cohort + patientid** for summaries unless a verified cross-cohort identity linkage exists.

**Check:** One molecular sample should resolve to an appropriate clinical patient record; any many-to-many or uncertain match requires documented review.

Clinical variables must be evaluated at their appropriate observation level. Treatment, response, and sampling timepoint information may change within a patient; longitudinal differences should not automatically be classified as conflicting records. Confirm whether apparently inconsistent values reflect separate treatment episodes, samples, or assessment dates before flagging a patient-level conflict.

### 5.2 Required fields versus unavailable fields

The MAR-40 target schema includes standardized fields such as `patientid`, `treatmentid`, `response`, `tissueid`, `survival_time_os`, `survival_time_pfs`, `survival_unit`, and the corresponding event indicators. Preserve these as the **target schema** where relevant; a cohort is not automatically ineligible because the source lacks a field.

| Domain | MAR-40 target examples | Key validation question |
| --- | --- | --- |
| Identifiers | `patientid`, `sampleid`, `treatmentid` | Are patient, sample, and therapy records distinguishable? |
| Disease | `cancer_type`, `tissueid`, `histo`, `stage` | What exact disease classification and source terminology were used? |
| Demographics | `age`, `sex` | Are units and coding documented? |
| Therapy | `treatment`, `target` | Is the drug/regimen and treatment context supported by the source? |
| Outcome | `recist`, `response` | Is the definition of response and assessment timepoint explicit? |
| Survival | `survival_time_os`, `event_occurred_os`, `survival_time_pfs`, `event_occurred_pfs`, `survival_unit` | Are time origin, endpoint definition, censoring and units confirmed? |
| Assays | `rna`, `rna_info`, `dna`, `dna_info` | Is assay availability distinguished from assay type and processing method? |

For the complete current target schema and accepted values, use [Data dictionary](data_dictionary.md). **Do not treat the example field list here as a replacement for the version-controlled dictionary.**

### 5.3 Harmonization decision procedure

For each source column:

1. Retain the source column name and original values in a source-to-target mapping record.
2. Confirm the source definition from the publication, metadata file, protocol, or data provider.
3. Select a target MAR-40 variable only where the meanings align.
4. Specify the transformation (rename, recode, unit conversion, join, derived value, or no mapping).
5. Record the decision status: **Direct**, **Conditional**, **Needs review**, or **Unmapped**.
6. Document the reviewer, date, and evidence for clinical/biological interpretation changes.
7. Re-run checks after updating a mapping rule; never edit only the final exported table.

**Suggested mapping-log fields:** `cohort`, `source_file`, `source_variable`, `source_definition`, `target_variable`, `rule_id`, `transformation`, `mapping_status`, `evidence`, `reviewer`, `review_date`, `notes`.

### 5.4 Cancer taxonomy and disease annotations

Map source disease labels to the agreed [OncoTree](https://oncotree.mskcc.org/) version. Maintain **Level 1 cancer type** as the shared broad classification and **Level 2 subtype** when known and supported. Retain the unmodified original tumor label and the exact mapping code/version.

Ambiguous histology, multiple primaries, metastatic specimen labels, or unsupported subtype assignments must be flagged rather than inferred.

### 5.5 Treatment and response

Immunotherapy categories include: **PD-1/PD-L1**, **CTLA4**, **IO+combo**, **IO+chemo**, and **IO+targeted**. Preserve original regimen and component drug names; use agreed MAR-40 categories only after recording a documented mapping. Combination categories require an explicit precedence or multi-label rule agreed by participating teams.

Keep **RECIST best response** (`CR`, `PR`, `SD`, `PD`, or evaluability status when supported) separate from **binary responder/non-responder** outcome. Do not derive binary response from RECIST unless the study-specific response definition and threshold are documented. Record the assessment system/version and response timepoint when available. Stable disease and non-evaluable responses must not be assigned to a binary category without an explicitly documented, study-specific rule.

### 5.6 Survival endpoints

- Store OS and PFS times separately from their event indicators.
- Represent event values only after verifying the source's event/censoring convention (e.g. 1 = event, 0 = censored); never assume a coding direction.
- Use **months** for harmonized survival duration; preserve original units, the conversion method, and the agreed precision.
- Verify the **time origin** (diagnosis, treatment initiation, randomization, etc.). Do not pool survival measurements with incompatible or unknown origins without explicit analytical justification.
- Distinguish **metadata availability** (at least one nonmissing time **or** event field) from **analysis readiness** (a valid paired time/event record and a known endpoint definition).

### 5.7 Alignment with oncology metadata standards

MAR-40 harmonizes relevant clinical metadata using selected concepts from **mCODE** and **ICGC-ARGO**, adapted into the MAR-40 research data dictionary. This is a mapping reference and does not establish full implementation or certification against either specification. For response, survival, treatment and specimen timepoints, preserve source meanings and document every transformation; see [Clinical Metadata Standardization](clinical_metadata_standardization.md).

## 6. Molecular data curation

### 6.1 Inventory available assay data

The curation workflow covers processed RNA-seq counts/TPM, microarray expression, RNA-seq FASTQ, SNV mutation files, and CNA segment or matrix data. For each assay record the originating platform, sample IDs, reference genome, gene annotation, pipeline/tool versions, normalization, filtering, and quality metrics where available.

### 6.2 RNA expression

- Prefer source-supported normalized expression values and record their measurement scale.
- An example expression transformation is ***`log2(TPM + 1)`***. This is an assay-specific processing option, not a universal conversion rule: confirm applicability and document the pseudocount, normalization method, and whether the values were already transformed.
- If deriving TPM from counts, use documented feature lengths appropriate to the quantification level and record the source of lengths. Do not apply the illustrative conversion without validating gene-length definitions and the input's count type.
- For microarrays, retain the platform, probe-to-gene mapping, and source normalization information; do not label microarray values as TPM.

### 6.3 Mutation and copy-number data

- Record mutation type (SNV/indel), input format (e.g. VCF, MAF, gene-by-sample calls), variant-calling provenance, genome build, and filtering.
- Record CNA data representation (segments, copy-number calls, or gene-level matrix), reference genome and mapping methods.
- Where a binary gene-by-sample matrix is generated, preserve the logic converting raw calls to binary values and retain exclusions/uncertainties.

### 6.4 Annotation versions

Use consistent gene annotations across datasets where scientifically appropriate, while preserving source provenance and compatibility with the reference genome:

- **Source-reported annotations:** Retain and document the original gene annotation and reference genome when known; do not relabel existing values as originating from another release.
- **Standardized reprocessing:** For datasets with accessible raw data, use the agreed MAR-40 reference genome and gene annotation release, with versions and processing parameters recorded. GENCODE v40 may be used where the approved workflow specifies a compatible GRCh38-based reference.
- **Published/processed datasets with unknown annotations:** Record the annotation as unknown until verified. Do not assume GENCODE v19 solely because raw data are unavailable. Assess compatibility before any conversion or integration; GENCODE v19 is a GRCh37/hg19-associated release and should be used only when justified by the source or agreed mapping procedure.

Record the annotation release, reference genome, gene identifier format, and processing method for each dataset. Any conversion between annotation versions, gene identifiers, or genome builds must be explicitly documented and traceable, including the mapping strategy and any unmapped or duplicated features.

Established gene, drug, and tumor annotation resources should be used consistently, with the corresponding resource versions recorded.

### 6.5 Molecular harmonization and reference implementations

For detailed RNA expression scale/annotation handling, DNA SNV/CNA metadata, duplicate checks, and assay-specific QC, see [Molecular Data Standardization](molecular_data_standardization.md). **Snakemake is used for standardization/harmonization; Nextflow is planned for downstream MAR-40 analyses.** The BHK Lab [AnnotationGx](https://github.com/bhklab/AnnotationGx) and [ICB_Common](https://github.com/BHKLAB-DataProcessing/ICB_Common) repositories can guide annotation and ICB processing; adopted functions and reference versions must be explicitly documented and pinned. Their inclusion here does not imply full integration or validation in MAR-40.

## 7. Build harmonized objects and link clinical/molecular data

For R/Bioconductor workflows, supported integration objects include:

- `SummarizedExperiment` for expression or suitable feature-by-sample matrices.
- `RangedSummarizedExperiment` when genomic feature ranges are required.
- `MultiAssayExperiment` (MAE) to combine assays with clinical metadata and sample-to-patient links.

**Minimum structural checks:** `assay()` feature/sample axes match `rowData()` and `colData()`; each assay's sample IDs can be traced to the relevant patient; and `sampleMap()` relationships are checked rather than assumed. Maintain clear provenance when inputs differ by source, preprocessing or assay type.

MAE should be considered a **target integration representation**, not a requirement to fabricate molecular assays for a clinical-only cohort. The exact MAR-40 output contract and filenames should be defined in [Data dictionary](data_dictionary.md) and [Usage](usage.md).

## 8. Quality control and release gates

Quality control (QC) is performed at three stages: **source data**, **post-harmonization**, and **integrated outputs**. Apply the checks relevant to each cohort and its available modalities; a clinical-only cohort does not require molecular-assay QC. Detailed validation rules, thresholds, and reporting conventions are maintained in the [Quality Control Guide](quality_control.md).

| QC stage | Key checks |
| --- | --- |
| **Source data** | Verify file readability, source versions and provenance, expected identifiers, original coding, and permitted data access. |
| **Post-harmonization** | Validate canonical field names and permitted values; patient/sample uniqueness and linkage; supported disease, treatment, response, and survival mappings; missingness and unresolved decisions. |
| **Integrated outputs** | Confirm assay-to-sample/patient relationships, molecular feature identifiers, reference genome and annotation compatibility, assay dimensions and units, where applicable. Check generated outputs against input counts and documented transformations. |

**Cross-cutting QC requirements:**

- **Record granularity:** Assess duplicates and apparent conflicts at the correct patient, sample, treatment, or assessment level. Longitudinal changes are not automatically errors.
- **Clinical interpretation:** Verify response criteria, survival time origins, event/censoring codes, and derived variables before considering data analysis-ready.
- **Completeness and provenance:** Summarize missingness by cohort and relevant record level; retain source-to-target mapping decisions, exceptions, and applicable software/configuration versions.
- **Issue tracking:** Document each material discrepancy, its impact, resolution or outstanding status, and responsible reviewer. Do not silently impute missing values or discard records.

### 8.1 QC review and release decision

Assign a documented disposition to each cohort or release:

- **Pass:** Applicable QC checks are satisfied, provenance is documented, and no material unresolved issues remain.
- **Pass with documented limitations:** Noncritical missingness or limitations remain, but their impact and permitted use are recorded and approved by the designated reviewer.
- **Hold for review:** Material clinical or molecular ambiguities, invalid patient/sample links, failed structural checks, or unresolved data-access concerns prevent release until reviewed.

Record the QC disposition, reviewer, review date, outstanding issues, and any restrictions in the cohort QC summary. A **Pass** indicates completion of the specified curation checks, not automatic suitability for every downstream analysis.

The [Snakemake cohort visualization workflow](visualization_workflow.md) provides **descriptive QC support**, including cohort summaries, variable-availability and missingness reports, and selected conflict flags. Its plots and tables do **not** replace source-level validation, scientific review, or endpoint-specific analysis-readiness checks. In particular, a nonmissing survival time **or** event field does not establish a valid time–event pair.

## 9. Outputs, reproducibility, and handoff

Suggested cohort handoff contents, subject to institutional permissions:

```text
<cohort_id>/
├── source_manifest.tsv           # Source inventory, versions, permitted paths/checksums
├── mapping_log.tsv               # Source -> MAR-40 transformations and decisions
├── clinical_harmonized.csv       # Approved de-identified clinical metadata, if shareable
├── assay_manifest.tsv            # Available assays and processing parameters
├── qc_summary.tsv                # QC checks, results, exceptions
├── unresolved_issues.tsv         # Items requiring reviewer decisions
└── run_manifest.txt              # Git commit, environment, execution parameters, date
```

A molecular-data object (e.g. `.rds` MAE) may be produced in an approved destination when supported by the cohort and workflow. This is the recommended cohort handoff structure; include only files supported by the cohort and permitted by institutional access requirements.

The implemented [MAR-40 Snakemake visualization workflow](visualization_workflow.md) can generate standardized descriptive figures, cohort summaries, variable-availability and missingness reports, and supporting QC tables from harmonized sample-level metadata. These outputs support curation review but do not replace source-level validation, endpoint assessment, or scientific approval. The suggested handoff files above are not all automatically generated by that workflow.

Capture the following run details: source file versions/checksums, approved execution location, Git commit, Pixi/other environment lockfile, workflow command, tool versions, mapping version, start date, curator and reviewer. Scripts should be rerunnable without hard-coded local machine paths; use paths/configuration described in [Usage](usage.md).

### Suggested submission review checklist

- [ ] Data sources, access permissions, and provenance are documented.
- [ ] Clinical metadata follow the MAR-40 standardized data dictionary.
- [ ] Patient and sample identifiers are consistent and correctly linked.
- [ ] Cancer types, treatments, response, and survival variables are harmonized according to the agreed definitions.
- [ ] Molecular data processing, reference genomes, and source or approved target annotation versions are documented.
- [ ] Clinical and molecular data are correctly integrated, including MAE validation where applicable.
- [ ] Quality-control checks are completed, and unresolved issues are documented.
- [ ] Harmonized outputs and processing steps are reproducible using version-controlled scripts.

## 10. Handling exceptions and SOP changes

When a source requires a deviation, document the affected cohort, reason, alternative procedure, scientific impact, decision owner and approval date. Reusable deviations should be proposed as a versioned SOP or harmonization-rule update via repository review. Retain prior mapping versions so existing outputs remain interpretable.

## 11. Maintaining cross-site consistency

The harmonization framework is shared across participating MAR-40 teams. Each site should use the current version of the [Data dictionary](data_dictionary.md), [Data sources](data_sources.md), [Quality control](quality_control.md), and [Usage](usage.md) documentation when producing a cohort release.

Changes to shared variable definitions, OncoTree classifications, treatment grouping, clinical endpoints, assay representations, QC criteria, or output formats must be recorded in version-controlled documentation and reviewed by the designated scientific/data leads before being applied across cohorts. Site-specific exceptions remain traceable in the mapping log and QC report.

Changes affecting the interpretation of previously harmonized cohorts should trigger an assessment of whether existing outputs require regeneration. Preserve the source definitions, transformation rules, and previous output versions to support reproducibility.

**---**

### Document history

| Version | Date | Status | Summary |
| --- | --- | --- | --- |
| 1.0 | November 20, 2026 | Active | MAR-40 cross-site data curation and harmonization SOP for UCL, McGill University, and UHN; includes source provenance, clinical and molecular harmonization, QC, and reproducibility procedures. |
