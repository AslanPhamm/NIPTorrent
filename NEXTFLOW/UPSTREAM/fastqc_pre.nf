process fastqc_pre {
    tag "$sample_name"
    // Input: fastq file
    input:
    tuple val(sample_name), path(convert_fastq)
    // Output: quality control report
    output:
    tuple val(sample_name), path("${sample_name}_fastqc.zip"), path("${sample_name}_fastqc.html")   
    // Publish results
    publishDir "${params.outdir}/fastqc_pre", mode: 'copy', overwrite: true
    // Script: Run
    script:
    """
    fastqc --threads ${task.cpus} ${convert_fastq}
    """
}