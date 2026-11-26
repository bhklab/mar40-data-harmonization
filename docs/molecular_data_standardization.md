# Molecular Data Standardization and Annotation

**Status:** MAR-40 working conventions and recommended checks. Local Hwang clinical/RNA processing is technically demonstrated; broader cohort-level RNA and DNA QC and cross-site validation are ongoing.

## Scope and responsibilities

Use **Snakemake for curation, preprocessing, standardization, and harmonization** of clinical/molecular datasets. UHN coordinates the RNA-focused workflows and UCL coordinates the DNA-focused workflows, while both institutional inventories may contain multiple assay types. **Nextflow is the planned framework for downstream analyses throughout MAR-40**, and should not be represented here as an implemented standardization pipeline.

## Per-cohort molecular manifest

For every assay record: cohort, patient and sample identifiers, specimen/timepoint, assay type (RNA-seq/WTS, targeted RNA, microarray, SNV/indel, CNA, WES/WGS, etc.), raw/processed availability, source file/version, genome build, annotation release, normalization/transform, units, software versions, QC status and access restrictions.

## RNA expression processing and harmonization

1. Record whether input is FASTQ, counts, TPM, FPKM, log-scale expression, microarray or targeted panel. **Never label different measurement scales as equivalent.**
2. For raw RNA-seq, document reference genome/transcriptome, quantification method, feature lengths and import to gene level; retain the pipeline and annotation versions. Salmon/tximport may be used **only if selected and validated for that cohort**.
3. For processed profiles, preserve the original assay scale and transformation; log2(TPM + 1) is a possible analysis representation, **not a universal default**.
4. Harmonize gene identifiers using an agreed species/build/annotation release; preserve source IDs and a mapping audit (unmapped, ambiguous, duplicate identifiers). Do not assume all data share the same GENCODE version.
5. Preserve assay platform distinctions (bulk RNA-seq, NanoString, microarray); record probe-to-gene mappings and platform-specific preprocessing.
6. Match expression samples to clinical metadata using validated cohort/patient/sample keys; keep multiple timepoints/aliquots distinct.
7. Record sample-level QC and feature filtering **per cohort**, without silently imposing an external study's expression threshold.

## DNA processing and harmonization

1. Document DNA assay scope (panel/WES/WGS), reference build, callable territory, variant caller, filters and originating format (VCF/MAF/gene matrix).
2. Standardize gene and variant annotations with genome-build-aware mappings; preserve mutation consequences, raw calls, and provenance.
3. Keep SNV/indel and copy-number representations distinct; document rules for deriving gene-level or binary alteration matrices.
4. Record whether TMB is source-reported or derived, whether synonymous variants are excluded, assay territory and callable denominator; TMB comparisons require consistent measurement definitions.
5. Document sample purity, coverage, tumor-normal status and assay-specific QC when available; mark unavailable QC honestly.
6. Identify potential within-cohort and cross-cohort duplicates for scientific review; thresholds from earlier papers are **references**, not automatically MAR-40 QC policy.

## Annotation tools and reusable lab code

- **[AnnotationGx](https://github.com/bhklab/AnnotationGx):** BHK Lab resource for constructing/querying annotations. Assess the current interface and relevant reference sources before introducing it into MAR-40; pin a version or commit and record database releases and mapping outcomes.
- **[ICB_Common](https://github.com/BHKLAB-DataProcessing/ICB_Common):** Shared scripts/conventions that can inform immune-checkpoint-blockade cohort formatting and annotations. Document which functions are imported, exact commit, inputs and outputs; avoid downloading unpinned code at runtime.
- **GENCODE/HGNC/Ensembl or other reference sources:** Document reference genome, release and identifier crosswalk before applying any conversion. Do not assume feature identifiers from different releases are directly interchangeable.

## Required quality-control evidence

Report per-cohort: input/output sample counts, clinical linkage rate, assay units, identifier mapping rate, missing/duplicate features, filtered samples/features, source and target genome/annotation versions, and exceptions. Separate **documented design**, **implemented workflow**, and **executed QC** in technical and milestone reporting.

## Reproducibility and access

Record tool versions, reference checksums or immutable releases, Snakemake configuration, R/Bioconductor versions, upstream dependencies and QC outputs. Keep restricted patient-level files in authorized locations; commit only approved scripts, schemas, synthetic examples and shareable aggregate evidence.
