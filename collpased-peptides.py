import pandas as pd
import sys
import os

if len(sys.argv) < 2:
    print("Usage: python script.py <input_excel> [output_excel]")
    sys.exit(1)

input_file = sys.argv[1]

if len(sys.argv) >= 3:
    output_file = sys.argv[2]
else:
    base = os.path.splitext(os.path.basename(input_file))[0]
    output_file = f"{base}_collapsed.csv"

# Read the CSV
df = pd.read_excel(input_file)

# Get all column names
cols = list(df.columns)

# Find the position of "Expectation"
expectation_idx = cols.index("Expectation")

# Sample columns begin after the repeated "Spectrum" column
sample_cols = [c for c in cols[expectation_idx + 2:] if c != "Spectrum"]

# Metadata columns to keep
meta_cols = ["Protein Description",
             "Protein ID",
             "Gene",
             "Protein Start",
             "Protein End",
             "Assigned Modifications",
             "Total Glycan Composition"]

# Check required columns exist
required_cols = ["Modified Peptide", "Expectation"] + meta_cols
missing_cols = [c for c in required_cols if c not in cols]

if missing_cols:
    print("Error: missing required columns:")
    for c in missing_cols:
        print(f"  - {c}")
    sys.exit(1)


# Collapse rows by exact Modified Peptide
collapsed = (
    df.groupby("Modified Peptide", as_index=False)
      .agg(
          {
              "Protein Description": "first",
              "Protein ID": "first",
              "Gene": "first",
              "Protein Start": "first",
              "Protein End": "first",
              "Assigned Modifications": "first",
              "Total Glycan Composition": "first",
              **{col: "max" for col in sample_cols}
          }
      )
)

# Reorder columns
collapsed = collapsed[["Modified Peptide"] + meta_cols + sample_cols]

# Optional: count how many samples each peptide was found in
# collapsed["n_samples_found"] = collapsed[sample_cols].notna().sum(axis=1)

# Write output CSV
collapsed.to_excel(output_file, index=False)

print(f"Done. Wrote collapsed file to: {output_file}")
print(f"Number of unique modified peptides: {len(collapsed)}")
print("First few sample columns:", sample_cols[:10])
