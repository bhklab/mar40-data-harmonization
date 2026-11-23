# MAR-40 | Cohort visualization using the EXISTING R script
#   workflow/scripts/clinical_visualization.R
# This rule does not re-harmonize clinical data. Input is already standardized.
# The list of outputs matches MAR40 cohort visualization v1.1; if the local
# script differs, reconcile filenames before running.

FIGURE_FILES = [
    "01_cancer_donut.png",
    "02_treatment_donut.png",
    "03_clinical_availability_heatmap.png",
    "03_clinical_availability_heatmap.pdf",
    "04_sex_by_cohort.png",
    "05_sampling_timing_by_cohort.png",
    "06_recist_by_cohort.png",
]

REPORT_FILES = [
    "cohort_summary.csv",
    "cohort_variable_missingness.csv",
    "cohort_clinical_availability.csv",
    "cohort_access_summary.csv",
    "cohort_unavailable_variables.csv",
    "patient_level_conflicts.csv",
    "assay_source_labels.csv",
    "observed_followup_summary.csv",
    "01_cancer_donut_counts.csv",
    "02_treatment_donut_counts.csv",
    "04_sex_by_cohort_counts.csv",
    "05_sampling_timing_by_cohort_counts.csv",
    "06_recist_by_cohort_counts.csv",
    "run_manifest.txt",
]

VISUALIZATION_FILES = FIGURE_FILES + REPORT_FILES

rule cohort_visualization:
    input:
        csv=lambda wc: config["datasets"][wc.dataset]["input"],
        script="workflow/scripts/clinical_visualization.R",
    output:
        expand(
            "results/visualization/{{dataset}}/{filename}",
            filename=VISUALIZATION_FILES,
        ),
    params:
        outdir=lambda wc: f"results/visualization/{wc.dataset}",
    log:
        "logs/visualization/{dataset}.log",
    threads: 1
    shell:
        """
        Rscript {input.script:q} {input.csv:q} {params.outdir:q} > {log:q} 2>&1
        """
