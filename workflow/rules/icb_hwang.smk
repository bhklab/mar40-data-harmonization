# ============================================================
# MAR-40 | Example 1: ICB_Hwang (GSE136961)
# Clinical + RNA Harmonization Workflow
# ============================================================
#
# Purpose:
#   Process GEO clinical and RNA data, harmonize molecular
#   and clinical metadata, and construct an expression-only
#   MultiAssayExperiment (MAE).
#
# Workflow:
#   1. GEO data preprocessing
#   2. Clinical metadata harmonization
#   3. Molecular data availability
#   4. RNA expression harmonization
#   5. MultiAssayExperiment construction
#
# All scientific processing uses R.
# Snakemake manages dependencies and execution.
#
# Configuration:
#   config/icb_hwang.yaml
#
# Entry point:
#   workflow/icb_hwang/Snakefile
#
# This workflow is independent of clinical visualization.
# ============================================================


# ------------------------------------------------------------
# 1. Load Hwang configuration
# ------------------------------------------------------------

# Configuration is loaded by workflow/icb_hwang/Snakefile.

H = config["hwang"]

H_ROOT = H["data_root"]
H_DOWNLOAD = H["download_dir"]
H_CURATED = H["curation_dir"]
H_ANNOT = H["annotation_file"]
H_TISSUE = H["tissue_annotation_file"]

H_RSCRIPT = H["rscript"]

H_SCRIPTS = "workflow/scripts/icb_hwang"


# ------------------------------------------------------------
# 2. GEO data preprocessing
# ------------------------------------------------------------

rule hwang_prepare_downloads:
    input:
        clinical=f"{H_DOWNLOAD}/GSE136961_series_matrix.txt.gz",
        expression=f"{H_DOWNLOAD}/GSE136961_TPM.tsv.gz",
        script=f"{H_SCRIPTS}/format_downloaded_data.R"

    output:
        clinical=f"{H_CURATED}/CLIN.txt",
        expression=f"{H_CURATED}/EXP_TPM.tsv"

    params:
        data_root=H_ROOT,
        rscript=H_RSCRIPT

    message:
        "ICB_Hwang: preprocessing GEO clinical and TPM data"

    shell:
        '"{params.rscript}" "{input.script}" "{params.data_root}"'


# ------------------------------------------------------------
# 3. Clinical metadata harmonization
# ------------------------------------------------------------

rule hwang_format_clin:
    input:
        clinical=f"{H_CURATED}/CLIN.txt",
        tissue=H_TISSUE,
        script=f"{H_SCRIPTS}/Format_CLIN.R"

    output:
        f"{H_CURATED}/CLIN.csv"

    params:
        data_root=H_ROOT,
        rscript=H_RSCRIPT

    message:
        "ICB_Hwang: harmonizing clinical metadata"

    shell:
        '"{params.rscript}" "{input.script}" "{params.data_root}"'


# ------------------------------------------------------------
# 4. Molecular data availability
# ------------------------------------------------------------

rule hwang_availability:
    input:
        clinical=f"{H_CURATED}/CLIN.txt",
        expression=f"{H_CURATED}/EXP_TPM.tsv",
        script=f"{H_SCRIPTS}/Format_cased_sequenced.R"

    output:
        f"{H_CURATED}/cased_sequenced.csv"

    params:
        data_root=H_ROOT,
        rscript=H_RSCRIPT

    message:
        "ICB_Hwang: checking RNA and DNA data availability"

    shell:
        '"{params.rscript}" "{input.script}" "{params.data_root}"'


# ------------------------------------------------------------
# 5. RNA expression harmonization
# ------------------------------------------------------------

rule hwang_format_expr:
    input:
        expression=f"{H_CURATED}/EXP_TPM.tsv",
        availability=f"{H_CURATED}/cased_sequenced.csv",
        script=f"{H_SCRIPTS}/Format_EXPR.R"

    output:
        f"{H_CURATED}/EXPR.csv"

    params:
        data_root=H_ROOT,
        rscript=H_RSCRIPT

    message:
        "ICB_Hwang: harmonizing RNA expression (log2 TPM + 1)"

    shell:
        '"{params.rscript}" "{input.script}" "{params.data_root}"'


# ------------------------------------------------------------
# 6. MultiAssayExperiment construction
# ------------------------------------------------------------

rule hwang_create_mae:
    input:
        clinical=f"{H_CURATED}/CLIN.csv",
        expression=f"{H_CURATED}/EXPR.csv",
        availability=f"{H_CURATED}/cased_sequenced.csv",
        annotation=H_ANNOT,
        script=f"{H_SCRIPTS}/create_MAE.R"

    output:
        H["mae_file"]

    params:
        data_root=H_ROOT,
        rscript=H_RSCRIPT

    message:
        "ICB_Hwang: constructing MultiAssayExperiment"

    shell:
        '"{params.rscript}" "{input.script}" "{params.data_root}"'