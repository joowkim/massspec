import csv
import argparse

def parse_header(line):
    line = line.strip()
    if not line:
        raise ValueError("Empty line")

    line = line.lstrip(">")

    parts = line.split("|", 2)
    if len(parts) < 3:
        raise ValueError(f"Header does not have expected pipe format: {line}")

    accession = parts[1]
    rest = parts[2]

    rest_parts = rest.split(" ", 1)
    if len(rest_parts) < 2:
        raise ValueError(f"Header missing description: {line}")

    description = rest_parts[1]

    if " OS=" not in description:
        raise ValueError(f"Missing OS= field in header: {line}")

    protein_name = description.split(" OS=")[0].strip()

    gene_name = ""
    if " GN=" in description:
        gene_name = description.split(" GN=")[1].split(" ")[0].strip()

    return {
        "accession": accession,
        "protein_name": protein_name,
        "gene_name": gene_name
    }

def main():
    parser = argparse.ArgumentParser(
        description="Parse UniProt-style FASTA headers into TSV."
    )
    parser.add_argument("-i", "--input", required=True, help="Input FASTA file")
    parser.add_argument("-o", "--output", required=True, help="Output TSV file")
    args = parser.parse_args()

    rows = []

    with open(args.input, "r", encoding="utf-8") as f:
        for line_number, line in enumerate(f, start=1):
            line = line.strip()
            if not line or not line.startswith(">"):
                continue

            try:
                row = parse_header(line)
                rows.append(row)
            except ValueError as e:
                raise ValueError(f"Line {line_number}: {e}")

    with open(args.output, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(
            f,
            fieldnames=["accession", "protein_name", "gene_name"],
            delimiter="\t"
        )
        writer.writeheader()
        writer.writerows(rows)

    print(f"Saved to {args.output}")

if __name__ == "__main__":
    main()

