process gender {
    // Predict gender from BAM files
    input:
    path bam_list, stageAs:"bam_list/*"
    val out_dir
    // Output channels
    output:
    path "*.tsv", emit: tsv
    path "*.csv", emit: csv
    path "threshold.txt", emit: txt
    // Publish results
    publishDir "${params.outdir}/${out_dir}/gender_prediction", mode: 'copy'
    // Script run
    script:
    """
    # Set up a safe temporary directory for R/Python tools
    export TMPDIR=\$(mktemp -d)
    echo "TMPDIR is set to \$TMPDIR"

    for file in bam_list/*.bam; do
        echo \$file >> bam_file.txt
    done

    gender.py -s bam_file.txt
    """
}
