process rm_dup {
    
    input:
    tuple val(sample_name), path(sorted_bam)
    // Output: bam file
    output:
    tuple val(sample_name), path("${sample_name}_rmdup.bam")

    // Publish results
    publishDir ("${params.outdir}/rm_dup", mode: 'copy', overwrite: true)

    script:
    """
    samtools markdup -@ ${task.cpus} -r "${sorted_bam}" "${sample_name}_rmdup.bam"
    rm "${sorted_bam}"
    """
}
