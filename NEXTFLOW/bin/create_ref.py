#!/usr/bin/env python

import os
import random
import subprocess
import pandas as pd

def read_csv(_file,_sep):
    _df = pd.read_csv(_file, sep = _sep,keep_default_na = False, na_values = [""])
    return _df


def read_file(_file):
    with open(_file) as f1:
        data = [elm.strip() for elm in f1.readlines()]

    return data

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


def write_list(_list,output):
    with open(output,'w') as f1:
        for elm in _list:
            f1.write("{}\n".format(elm))

def list_sampling(_list,n):

    """
    Take a list x samples and return a random list of n samples

    :param _list: list of files to sample.
    :param n: an integer value, indicates the number of samples to select.
    :return: a list of samples files of length n.
    """
    if len(_list) < n:
        print(f"Warning: Requested sample size {n} exceeds available samples {len(_list)}. Sampling all available samples.")
        return _list.copy()
    sampling = random.sample(_list, n)
    return sampling

def list_gender(dict_gender):

    """
    Separates sample name in 2 list, one for girls and one for boys.

    :param dict_gender: a dict with gender associated with sample name
    :return: 2 list of sample name.
    """

    list_girl = list()
    list_boy = list()

    # Iterates over each sample and gender pair in the dict_gender, distributed to list_girl and list_boy
    for sample, gender in dict_gender.items():
        if gender == "F":
            list_girl.append(sample)
        elif gender == "M":
            list_boy.append(sample)
        else:
            print(f"Warning: Sample '{sample}' has undefined gender '{gender}'. Skipping.")

    print(f"Total girls: {len(list_girl)}, Total boys: {len(list_boy)}")
    return list_girl, list_boy

def csv_to_dict(_file, _sep):
    """
    Works only with a 2 col df
    :param _file:
    :param _sep:
    :return:
    """
    _df = read_csv(_file, _sep)
    _dict = dict(zip(list(_df.iloc[:,0]), list(_df.iloc[:,1])))
    return _dict


def create_link(input_dir, output_dir, my_ext, my_list):

    """
    Creates hardlink of files selected to be used as files of reference.

    :param input_dir: directory where are stored the original files
    :param output_dir: directory where hardlink will be created
    :param my_ext: extension of files for which a hardlink will be created (should be *.pickle, *.gcc or *.npz)
    :param my_list: list of files for which hardlink will be created
    :return:
    """

    my_list2 = gather_files(input_dir, my_ext, my_list)
    for elm in my_list2:
        my_hardlink = os.path.join(output_dir,os.path.basename(elm))
        if not os.path.isfile(my_hardlink):
            os.link(elm, my_hardlink)
        else:
            print("File exists: {} -> {}".format(elm, my_hardlink))


def create_wisex_ref(_cpu, binSizeNpz, _input, _npz):

    """
    Wrapper calling WisecondorX to create reference file in .npz format.

    :param _cpu: number of cpu to use
    :param binSizeNpz: binsize to use
    :param _input: list of files to use (in str format) e.g. : "sample1 sample2 sample3"
    :param _npz: filename for output
    :return:
    """

    cmd_wisex = 'WisecondorX newref --nipt --cpus {cpu} --binsize {binsize} {input} {output}'.format(cpu = _cpu, binsize = binSizeNpz, input = _input, output = _npz,)
    p = subprocess.Popen(cmd_wisex, shell=True, stdout=subprocess.PIPE)
    out, err = p.communicate()

def main():
    import argparse
    import configparser

    gender_table = "gender_prediction.csv"

    # my_outdir = os.path.expanduser(os.path.join(my_home, my_outdir))
    my_outdir = os.getcwd()
    my_outdir_npz = os.path.join(my_outdir, "npz")
    my_girldir = os.path.join(my_outdir, "girldir")
    my_boydir = os.path.join(my_outdir, "boydir")
    input_dir = os.getcwd()
    wisex_ref = os.path.join(my_outdir, "wisecondorx_reference.npz")

    list_dir = [my_outdir, my_outdir_npz, my_girldir, my_boydir]

    for my_dir in list_dir:

        if os.path.isdir(my_dir) == False:
            print("creates {}".format(my_dir))
            os.mkdir(my_dir)

    parser = argparse.ArgumentParser(description='Create a list of n files to use as a reference')
    parser.add_argument('file', type=str, help='List of prefix files to use.')
    parser.add_argument('-n', '--number', type=int, default=100,
                        help='Number of samples to keep in the list of reference. Default = 100')
    parser.add_argument('-b', '--binSizeNpz', type=int, default=1000000,
                        help='Scale samples to this binsize, multiples of existing binsize only (default: 30000)')
    parser.add_argument('-c', '--cpus', type=int, default=1,
                        help='Use multiple cores to find reference bins. Default = 1')

    args = parser.parse_args()

    my_list = read_file(args.file)

    # check if gender prediction table exists

    if not os.path.isfile(gender_table):
        print("{} is missing in directory. Please Use Preci_gender module first to compute gender prediction.".format(
            gender_table))

    else:

        dict_gender = csv_to_dict(os.path.join(gender_table), "\t")
        list_girl, list_boy = list_gender(dict_gender)

        # check intersection between list of prefix and list of gender

        list_girl = list(set(my_list).intersection(list_girl))
        list_boy = list(set(my_list).intersection(list_boy))

        k = 0

        if args.number % 2 == 0:
            k = int(args.number / 2)
        else:
            k = int((args.number - 1) / 2)

        # create a random list

        sampling_girl = list_sampling(list_girl, k)
        sampling_boy = list_sampling(list_boy, k)
        sampling = sampling_girl + sampling_boy

        # write the random list to a file named "reference_files.txt"
        write_list(sampling, os.path.join(my_outdir_npz, "reference_files.txt"))
        write_list(sampling_girl, os.path.join(my_girldir, "reference_files.txt"))
        write_list(sampling_boy, os.path.join(my_boydir, "reference_files.txt"))

        """
        create hardlink.
        take as input :
            - the directory where are stored the converted files .gcc, .pickle and .npz files.
            - the directory where we'll place the hardlink
            - an extension, either .gcc, .pickle or .npz.
            - a list of prefix randomly selected

        """
        create_link(input_dir, my_outdir_npz, ".npz", sampling)
        create_link(input_dir, my_girldir, ".gcc", sampling_girl)
        create_link(input_dir, my_girldir, ".pickle", sampling_girl)
        create_link(input_dir, my_boydir, ".gcc", sampling_boy)
        create_link(input_dir, my_boydir, ".pickle", sampling_boy)

        ##create wisecondorx reference file with npz randomly selected
        list_npz = gather_files(my_outdir_npz, ".npz", sampling)
        create_wisex_ref(args.cpus, int(args.binSizeNpz), " ".join(list_npz), wisex_ref)


if __name__ == '__main__':
    main()





