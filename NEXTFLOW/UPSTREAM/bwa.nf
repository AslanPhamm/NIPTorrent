process bwa {
    tag "$sample_name"
    // Input: fastq file
    input:
    tuple val(sample_name), path(read)
    // Output: bam file
    output:
    tuple val(sample_name), path("${sample_name}.bam")
    // Publish results
    publishDir "${params.outdir}/sam_bwa", mode: 'copy', overwrite: true
    // Script: Run
    script:
    """
    bwa mem -t ${task.cpus} ${params.ref_bwa} ${read} > ${sample_name}.sam
    samtools view -bS ${sample_name}.sam > ${sample_name}.bam
    """
}
