process ref {
    // Create reference from converted files
    input:
    path gcc_files
    path pickle_files
    path npz_files
    path csv_table
    // Output channels
    output:
    path "boydir", emit: boy_ref
    path "girldir", emit: girl_ref
    path "npz", emit: npz_ref
    path "wisecondorx_reference.npz", emit: npz
    // Publish results
    publishDir "${params.outdir}/reference", mode: 'copy'
    // Script run
    script:
    """
    for file in ./*.gcc; do
        prefix=\$(basename \$file '.gcc')
        echo \$prefix >> prefix_sample.txt
    done

    create_ref.py prefix_sample.txt -c ${task.cpus} -n ${params.refSize}
    """
}