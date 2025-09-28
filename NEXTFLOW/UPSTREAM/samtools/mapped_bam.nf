process mapped_bam {
    // Map BAM files to remove unmapped reads
    input:
    tuple val(sample_name), path(rmdup_bam)
    //  Output channels
    output:
    tuple val(sample_name), path("${sample_name}.bam")
    // Publish results
    publishDir ("${params.outdir}/mapped", mode: 'copy', overwrite: true)

    script:
    """
    samtools view -@ ${task.cpus} -F 4 -b ${rmdup_bam} > ${sample_name}.bam
    rm ${rmdup_bam}
    """
}

