process ff_male {
    input:
    path boy_ref
    path girl_ref
    path gcc_files
    path pickle_files
    
    output:
    path "ff_male.tsv", emit: tsv

    // Publish results
    publishDir "${params.outdir}/ff_male", mode: 'copy'

    script:
    """
    # Set up a safe temporary directory for R/Python tools
    export TMPDIR=\$(mktemp -d)
    echo "TMPDIR is set to \$TMPDIR"
    
    for file in ./*.gcc; do
        prefix=\$(basename \$file '.gcc')
        echo \$prefix >> prefix_sample.txt
    done

    defrag.py prefix_sample.txt
    """
}