# ICB_Hwang: MAR-40 Clinical + RNA example

Source repository: https://github.com/RibaA/ICB_Hwang

- `download/` — original GEO source inputs and downloaded/preprocessed source files, when available and permitted.
- `annot/` — the source project's annotation resources (including **GENCODE v19** and tissue references, where available and licensed for this use).
- `curation/` — generated harmonized clinical/RNA tables and the `MultiAssayExperiment` (MAE); regenerate these with the integrated workflow.

The source code is maintained separately under `workflow/scripts/icb_hwang/`. For the RNA transformation, the intended processing is **`log2(TPM + 1)`**; confirm that the imported script and workflow reproduce this.

Some source files or annotation files may not be present in the public Git repository. Obtain missing inputs only from their authorized original sources. Do not commit controlled/private data or redistribute annotation resources without checking licensing. Generated outputs should generally not be committed.

To copy locally available source inputs from the original clone, run from the MAR-40 repository root:

```bash
bash tools/copy_icb_hwang_data.sh
```

Or specify the original data directory explicitly:

```bash
bash tools/copy_icb_hwang_data.sh /c/path/to/ICB_Hwang/data
```

This operation copies `download/` and `annot/` without overwriting destination files. It deliberately **does not copy** previously generated `curation/` outputs; generate them using the adapted Snakemake rules once they have been tested.
