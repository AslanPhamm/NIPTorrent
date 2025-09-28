#!/usr/bin/env python

import subprocess
import re
import argparse
import configparser
import os
import pandas as pd

r_exec = 'Rscript'
# r_script = './neso/seqff.r'
# seqffdir = './neso/'

current_dir = os.path.dirname(os.path.abspath(__file__))
assets_dir = os.path.join(current_dir, "../assets")
r_script = os.path.join(assets_dir, "seqff.r") 
seqffdir = assets_dir
pattern = re.compile('SeqFF')


def read_file(_file):
    with open(_file) as f1:
        data = [elm.strip() for elm in f1.readlines()]

    return data

def write_df(_dict,columns,output):

    """
    :param _dict: A dictionary {"sample_name" : [value], ...} or {"sample_name" : value, ...}
    :param columns: A list of colname
    :param output: Output file name
    :return: A .csv file

    Writes a dict into a csv file
    """

    _df = pd.DataFrame.from_dict(_dict, orient='index', columns=columns[1:])
    _df.reset_index(level=0, inplace=True)
    _df.rename(columns={'index': 'sample'}, inplace=True)
    _df.to_csv(output, sep='\t', index=False, na_rep='NA')


# def execute_seqff(target):

#     """
#     Call Seqff Rscript to compute ff

#     :param target: path to bamfile. e.g. /path/to/bamfile.bam
#     :return: the result of seqff in str format.R
#     """
#     my_cmd = "samtools view {} | awk '{{if ($3 != \"chrM\" && $3 != \"*\") print $3\" \"$4}}'| Rscript {} {} {}".format(target, r_script, "/dev/stdin", seqffdir)
#     p = subprocess.run(my_cmd, stdout=subprocess.PIPE, shell=True)
#     result = p.stdout.decode('utf-8')

#     return result

def execute_seqff(target):
    """
    Call SeqFF Rscript to compute ff
    :param target: path to bamfile. e.g. /path/to/bamfile.bam
    :return: the result of seqff in str format.
    """
    my_cmd = f'Rscript {r_script} {target} {seqffdir}'
    p = subprocess.run(my_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    result = p.stdout.decode('utf-8')
    
    if p.returncode != 0:
        err = p.stderr.decode('utf-8')
        print(f"Error in Rscript:\n{err}")
        return None

    return result


def main():
    parser = argparse.ArgumentParser(description='')
    parser.add_argument('file', type=str, help='List of bam files to use. Should contain absolute path of bam files.')
    args = parser.parse_args()

    table_dir = os.getcwd()

    my_output_file = os.path.join(table_dir, "ff_all.tsv")


    _dict = dict()

    _list = read_file(args.file)
    if not _list:
        pass

    else:

        for sample in _list:
            _tmp_dict = {}
            _sample_name = os.path.basename(sample).split(".")[0]
            _res = execute_seqff(sample)
            _values = _res.split("\n")[1]

            #takes only seqff value
            _tmp_dict[_sample_name] = _values.split()[0]
            _dict.update(_tmp_dict)


        write_df(_dict,["sample", "ff (Seqff)"], my_output_file)




if __name__ == '__main__':
    main()

