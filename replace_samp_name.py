import argparse
import os.path
import re
from typing import List, Dict


def read_sample_key(sample_key: str) -> Dict[str, str]:
    if not os.path.isfile(sample_key):
        raise FileNotFoundError(f"{sample_key} is not found!")
    res_dict: Dict[str, str] = {}
    with open(sample_key) as fin:
        fin.readline()  # skip header
        for line in fin:
            tmp: List[str] = line.strip().split(",")
            samp_name: str = tmp[0]
            file_name: str = tmp[1]
            res_dict[file_name] = samp_name
    return res_dict


def replace_file_name_w_samp_name(col_header: List[str], samp_key: Dict[str, str]) -> str:
    res_list: List[str] = list()
    for colname in col_header:
        # colname can be
        # "[1] tims_26apr0613_Slot2-31_1_14771.d.EG.TotalQuantity (Settings)",
        # "[53] tims_26apr0668-re_Slot2-9_1_14880.d.EG.TotalQuantity (Settings)"
        if not "tims_" in colname:
            res_list.append(colname)
        else:
            # Regex breakdown for r'\]\s+(.+?)_Slot\d':
            #   Part      | Meaning
            #   ----------|------------------------------------------------------
            #   \]        | match a literal ]
            #   \s+       | match one or more spaces after it
            #   (.+?)     | capture group: any characters, non-greedy
            #   _Slot\d   | match literal _Slot followed by one digit
            # e.g. "[1] tims_26apr0613_Slot2-31_..." -> group(1) == "tims_26apr0613"
            match = re.search(r'\]\s+(.+?)_Slot\d', colname)

            if match is None:
                # print(f"No match found for: {colname}")
                raise ValueError(f"No match found for: {colname}")

            file_name: str = match.group(1)  # "tims_26apr0613"
            samp_name = samp_key.get(file_name)
            if samp_name is None:
                raise KeyError(f"'{file_name}' not found in sample key")
            res_list.append(samp_name)
    print(f"# columns in the spec output is {len(res_list)}")
    return (",".join(res_list))


def rewrite_spec_csv(spect_out: str, samp_key: Dict[str, str], output_f: str):
    if not os.path.isfile(spect_out):
        raise FileNotFoundError(f"{spect_out} is not found!")
    with open(spect_out) as fin, open(output_f, "w") as fout:
        col_header = fin.readline().split(",")
        new_header = replace_file_name_w_samp_name(col_header, samp_key)
        fout.write(new_header + "\n")
        for line in fin:
            fout.write(line)
    print(f"Output written to: {output_f}")


def main(sample_key: str, spect_out: str):
    samp_key = read_sample_key(sample_key)

    input_filename = os.path.basename(spect_out)
    output_f = os.path.join("./", f"renamed_{input_filename}")

    rewrite_spec_csv(spect_out=spect_out, samp_key=samp_key, output_f=output_f)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Replace raw file names with sample names in Spectronaut output.")
    parser.add_argument(
        "--samplekey",
        required=True,
        help="Path to sample key CSV -- 1st column: sample name, 2nd column: timstof file name"
    )
    parser.add_argument(
        "--spect",
        required=True,
        help="Path to Spectronaut peptide quantities CSV"
    )
    args = parser.parse_args()
    main(sample_key=args.sample_key, spect_out=args.spect_out)
