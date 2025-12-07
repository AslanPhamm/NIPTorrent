process defrag_b {
    input:
    tuple path(boy_dir), path(girl_dir), path(gcc), path(pickle)
    path (gender_csv)
    
    output:
    path "defrag_b.tsv", emit: tsv
    // Publish results
    publishDir "${params.output_dir}/defrag_b", mode: 'copy'

    script:
    """
    ${projectDir}/bin/defrag_b.py ${pickle} ${girl_dir} ${pickle.baseName}.defrag_b.tsv ${gender_csv}
    """
}