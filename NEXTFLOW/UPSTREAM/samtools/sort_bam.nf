process sort_bam {
    tag { sample_name }
    // Input: bam file
    input:
    tuple val(sample_name), path(bwa)
    // Output: sorted bam file
    output:
    tuple val(sample_name), path("${sample_name}_sorted.bam")
    
    // Publish results
    publishDir ("${params.outdir}/sorted_bam", mode: 'copy', overwrite: true)

    script:
    """
    samtools sort -@ ${task.cpus} -O bam "${bwa}" -o "${sample_name}_sorted.bam"
    """
}
