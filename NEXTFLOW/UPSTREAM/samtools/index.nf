process index {
    
    input:
    tuple val(sample_name), path(mapped_bam)

    output:
    tuple val(sample_name), path("${sample_name}.bam.bai")

    // Publish results
    publishDir ("${params.outdir}/mapped", mode: 'copy', overwrite: true)

    script:
    """
    samtools index -@ ${task.cpus} "${mapped_bam}"
    """
}
