process wisecondorX {
    // Predict abnormal results using Wisecondor
    input:
    path npz_files
    path ref_npz
    // Output channels
    output:
    path "copy_number_alteration_data", emit: abnormal_results
    path "abnormal_results.tsv", emit: tsv
    path "path_plots_wisecondorx.tsv", emit: plot_tsv
    // Publish results
    publishDir "${params.outdir}/wisecondorX", mode: 'copy', saveAs: { filename ->
        if (filename.endsWith('_aberrations.bed')) "aberrations/$filename"
        else if (filename.endsWith('_bins.bed')) "bins/$filename"
        else if (filename.endsWith('_segments.bed')) "segments/$filename"
        else if (filename.endsWith('_statistics.txt')) "statistics/$filename"
        else if (filename.endsWith('.plots')) "plots/$filename"
        else null
    }

    // Script run
    script:
    """
    # Set up a safe temporary directory for R/Python tools
    export TMPDIR=\$(mktemp -d)
    echo "TMPDIR is set to \$TMPDIR"
    
    for file in ./*.npz; do
        if [[ "\$file" == */"wisecondorx_reference.npz" ]]; then
            continue
        fi
        prefix=\$(basename \$file '.npz')
        echo \$prefix >> prefix_sample.txt
    done

    ${projectDir}/bin/wisecondor.py prefix_sample.txt
    """
}