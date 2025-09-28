process convert_fastq {
    tag "$sample_name"
// Input: bam file
    input:
    tuple val(sample_name), path(read)
// Output: fastq file
    output:
    tuple val(sample_name), path("${sample_name}.fastq.gz")
// Publish results
    publishDir("${params.outdir}/fastq", mode: 'copy', overwrite: true)
// Script: Run
    script:
    """
    samtools fastq -@ ${task.cpus} "${read}" | gzip > "${sample_name}.fastq.gz"
    """
}
