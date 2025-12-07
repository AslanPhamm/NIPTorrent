#!/usr/bin/env python

import subprocess
import argparse
import os
import pandas as pd

r_exec = 'Rscript'

current_dir = os.path.dirname(os.path.abspath(__file__))
assets_dir = os.path.join(current_dir, "../assets")
r_script = os.path.join(assets_dir, "seqff.r") 
seqffdir = assets_dir

def execute_seqff(sample_path):
    """
    Call SeqFF Rscript to compute ff.

    :param sample_path: Path to a single BAM file
    :return: Floating-point FF value
    """
    cmd = f"samtools view {sample_path} | awk '{{if ($3 != \"chrM\" && $3 != \"*\") print $3\" \"$4}}' | Rscript {r_script} /dev/stdin {seqffdir}"
    
    result = subprocess.run(cmd, stdout=subprocess.PIPE, shell=True, text=True)
    
    output_lines = result.stdout.split("\n")[1]

    return output_lines.split()[0]  # Extract FF value


def write_result(sample, ff_value, output_path):
    """
    Writes a single-sample FF result to a TSV file.
    """
    df = pd.DataFrame({"sample": [sample], "ff (SeqFF)": [ff_value]})
    df.to_csv(output_path, sep='\t', index=False, na_rep='NA')

def main():
    parser = argparse.ArgumentParser(description='Run SeqFF for a single BAM file')
    parser.add_argument('sample', type=str, help='Absolute path to a single BAM file')
    parser.add_argument('output', type=str, help='Output TSV file')

    args = parser.parse_args()
    
    sample_name = os.path.splitext(os.path.basename(args.sample))[0]
    
    ff_value = execute_seqff(args.sample)
    
    write_result(sample_name, ff_value, args.output)

if __name__ == '__main__':
    main()