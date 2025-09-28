process filter {
    tag "$sample_name"

    input:
    tuple val(sample_name), path(fastq)

    output:
    tuple val(sample_name), path("${sample_name}.filtered.fastq.gz")

    publishDir("${params.outdir}/trim_fastq", mode: 'copy', overwrite: true)

    script:
    """
    trimmomatic SE -threads ${task.cpus} \
        ${fastq} "${sample_name}.filtered.fastq.gz" \
        SLIDINGWINDOW:10:15 MINLEN:30
    """
}
