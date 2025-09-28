#!/usr/bin/env python

import subprocess
import os
import argparse
import pandas as pd

wx_exec = 'WisecondorX'

def gather_files(_dir, _extension, _list, isdir = False):
    """

    :param _dir: Directory where file of interest are stored.
    :param _extension: Extension of file of interest.
    :param _list: List of files of interest. Look for those files in _dir.
    :param pattern: In some case we need to look for a pattern and not for an extension.
    :return: A list of files.

    Regroup files of interest from a directory and all the subdirectories.
    """
    check_list = list()
    """list_files = [os.path.join(root, file) for root, dirs, files in os.walk(_dir) for file in files if
                   file.endswith(_extension)]
    for file in list_files:
         if pattern is False:
             prefix = os.path.basename(file).split('.')[0]
         else :
             prefix = os.path.basename(file).split(_extension)[0]
         if prefix in _list:
             check_list.append(file)"""
    # if pattern is False:
    #     files_found = [os.path.basename(file).split('.')[0] for file in list_files]
    # else:
    #     files_found = [os.path.basename(file).split(_extension)[0] for file in list_files]
    #
    # # check_list = []

    if isdir is False:
        for prefix in _list:
            if os.path.isfile(os.path.join(_dir,prefix) + _extension):
                check_list.append(os.path.join(_dir,prefix) + _extension)
    else:
        for prefix in _list:
            if os.path.isdir(os.path.join(_dir, prefix) + _extension):
                check_list.append(os.path.join(_dir, prefix) + _extension)
    # return list_files
    return check_list

def read_file(_file):
    with open(_file) as f1:
        data = [elm.strip() for elm in f1.readlines()]

    return data


class Sao:

    def __init__(self, reference, resultdir):
        self.reference = reference
        self.resdir = resultdir

    def execute_wisecondorx(self, fname):

        """
        Wrapper to execute WisecondorX predict.

        :param fname: path to .npz file e.g. /path/to/npzfile.npz
        :return:
        """

        sample_name = os.path.basename(fname)#.split(".bam")[0]

        result = os.path.join(self.resdir, sample_name.split(".npz")[0])
        p = subprocess.Popen([wx_exec, 'predict', fname, self.reference ,result, "--bed", "--plot"]).wait()
        #p = subprocess.Popen([wx_exec, 'predict', fname, self.reference ,result, "--beta 0.15","--bed", "--plot"]).wait()

        return result

    def summarize_wisecondorx(self, liste_files, output_file, _sep = '\t'):

        """
        Summarize WisecondorX into one table in csv format where each row correspond to a sample and each col to a chr.

        :param liste_files: prefix of files to uses
        :param output_file: output file name where the df will be written
        :param _sep: separator to use e.g. '\t'
        :return:
        """

        dict_wise = {}
        for elm in liste_files:
 #           sample_name = os.path.basename(elm).split("_chr_statistics.txt")[0]
            sample_name = os.path.basename(elm).split("_statistics.txt")[0]         ###fix
            if sample_name not in dict_wise:
                dict_wise[sample_name] = {}
                with open(elm) as f1:
                    for line in f1.readlines():
#                       exclude_line = ('chr', 'Standard', 'Median')
                        exclude_line = ('chr', 'Standard', 'Median', 'Gender', 'Number', 'Copy' )   ###fix
                        if not line.startswith(exclude_line):
                            elm_line = line.split('\t')
                            chr, zscore = [elm_line[i] for i in (0, 3)]
                            if chr not in dict_wise[sample_name]:
                                dict_wise[sample_name][chr] = float(zscore)
                    if 'Y' not in dict_wise[sample_name]:
                        dict_wise[sample_name]['Y'] = 'NA'
                f1.close()


        with open(output_file, 'w') as f1:

            header = ['sample', 'chr1', 'chr2', 'chr3', 'chr4', 'chr5', 'chr6', 'chr7', 'chr8', 'chr9', 'chr10', 'chr11', 'chr12', 'chr13', 'chr14',
                      'chr15', 'chr16', 'chr17', 'chr18', 'chr19', 'chr20', 'chr21', 'chr22', 'chrX', 'chrY']
            f1.write(_sep.join(header) + '\n')

            for files in dict_wise.keys():
                zscore_value = []
                for zscore in dict_wise[files].values():
                    zscore_value.append(str(zscore))
                str_zscore = _sep.join(zscore_value)

                f1.write('{}{}{}\n'.format(files, _sep, str_zscore))

        f1.close()

def main():
    
    converted_dir = os.getcwd()
    resultdir = "copy_number_alteration_data"
    table_dir = os.getcwd()
    reference = "wisecondorx_reference.npz"

    if not os.path.isdir(resultdir):
        os.mkdir(resultdir)

    my_output_file = os.path.join(table_dir, "abnormal_results.tsv")

    parser = argparse.ArgumentParser(
        description='Execute WisecondorX prediction.')
    parser.add_argument('file', type=str, help='List of prefix files to use.')

    args = parser.parse_args()
    my_list = read_file(args.file)
    my_list_npz = gather_files(converted_dir, ".npz", my_list)

    s = Sao(reference, resultdir)
    for sample in my_list_npz:
        print(s.execute_wisecondorx(sample))

    #list_file_zscore = utils.gather_files(resultdir, "_chr_statistics.txt", my_list)
    list_file_zscore = gather_files(resultdir, "_statistics.txt", my_list)   ###fix

    s.summarize_wisecondorx(list_file_zscore, my_output_file)

    # create a df with plot path
    table_path = "path_plots_wisecondorx.tsv"
    dict_plot_path = dict()
    for elm in my_list:
        dict_plot_path[elm] = os.path.abspath(os.path.join(gather_files(resultdir, '.plots', [elm], isdir=True)[0],
                                           'genome_wide.png'))

    df_abs_fig_path = pd.DataFrame.from_dict(dict_plot_path, orient='index', columns=["path_wisex"])
    df_abs_fig_path.reset_index(level=0, inplace=True)
    df_abs_fig_path.rename(columns={'index': 'sample'}, inplace=True)

    output = os.path.join(table_dir, table_path)
    df_abs_fig_path.to_csv(output, sep='\t', index=False, na_rep='NA')


if __name__ == '__main__':
    main()

