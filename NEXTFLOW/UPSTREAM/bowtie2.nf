process bowtie2 {
    tag "$sample_name"
    // Input: fastq file
    input:
    tuple val(sample_name), path(read)

    // Output: bam file
    output:
    tuple val(sample_name), path("${sample_name}.bam")

    // Publish results
    publishDir "${params.outdir}/sam_bowtie2", mode: 'copy', overwrite: true

    // Script: Run
    script:
    """
    echo ${task.cpus}
    bowtie2 --very-sensitive -x $params.ref_bowtie2 \
        -U ${read} \
        -S ${sample_name}.sam \
        -p ${task.cpus}

    samtools view -bS ${sample_name}.sam > ${sample_name}.bam
    """
}