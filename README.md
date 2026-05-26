# massspec

Pre-processing and visualization utilities for label-free DIA proteomics data exported from Spectronaut.

## Setup

**Python** (requires Python 3.8+)

```bash
python -m venv .venv
source .venv/bin/activate
pip install pandas openpyxl
```

**R packages**

```r
install.packages(c("ggplot2", "ggrepel", "ggpubr", "stringr"))
BiocManager::install("ComplexHeatmap")
```

## Input files

All scripts expect input files in the `input/` directory. Run all commands from the **project root**.

### `sample_key.csv`

Maps raw instrument file names to human-readable sample names. Two columns, with a header row:

```
sample_name,Raw File Name
sample_01,tims_26apr0622
sample_02,tims_26apr0692
```

### Spectronaut peptide quantities CSV

Standard Spectronaut report export. Column headers for sample columns follow this format:

```
[N] tims_XXXXXX_Slot*_*_*.d.EG.TotalQuantity (Settings)
```

### Peptide-level Excel file (for collapsing)

Excel file with at minimum these columns: `Modified Peptide`, `Expectation`, `Protein Description`, `Protein ID`, `Gene`, `Protein Start`, `Protein End`, `Assigned Modifications`, `Total Glycan Composition`, plus one column per sample.

## Usage

### 1. Rename Spectronaut column headers

Replaces raw instrument file names in column headers with sample names from `sample_key.csv`.

```bash
python replace_samp_name.py \
  --sample-key input/sample_key.csv \
  --spect-out input/<spectronaut_file>.csv
```

Output is written to `output/renamed_<input_filename>.csv`.

### 2. Collapse peptide-level data

Collapses rows by `Modified Peptide`, keeping the max intensity per sample across duplicate peptide entries.

```bash
python collpased-peptides.py input/<peptide_file>.xlsx [output_file.xlsx]
```

If no output path is given, the file is saved as `<input_basename>_collapsed.csv` in the current directory.

### 3. Visualization (R)

Source `plot_utils.R` in your R analysis script to access four plotting functions:

```r
source("plot_utils.R")

plot_pca(pca_obj, meta_df = meta, color = "Group", label = "Sample")
plot_topN_sig_genes(top_genes, normalize_mat, sample_names)
plot_volcano(results_df, uniq_id = "Gene", logfc_id = "logFC", pval_id = "adj.P.Val")
plot_rle(log2_mat, meta, sample_name = "Sample")
```
