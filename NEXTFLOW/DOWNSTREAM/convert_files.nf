process convert_files {
    // Convert BAM files to .gcc, .pickle, .npz formats
    input:
    path bam_list, stageAs:"bam_list/*"
    val out_dir
    // Output channels
    output:
    path "*.pickle", emit: pickle
    path "*.gcc", emit: gcc
    path "*.npz", emit: npz
    // Publish results
    publishDir "${params.outdir}/${out_dir}/converted_files", mode: 'copy'
    // Script run
    script:
    """
    # Set up a safe temporary directory for R/Python tools
    export TMPDIR=\$(mktemp -d)
    echo "TMPDIR is set to \$TMPDIR"

    for file in bam_list/*.bam; do
        echo \$file >> bam_file.txt
    done

    convert.py \\
        --binSizePickle 1000000 \\
        --binSizeNpz 1000000 \\
        bam_file.txt
    """
}
