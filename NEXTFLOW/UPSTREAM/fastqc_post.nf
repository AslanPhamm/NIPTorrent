process fastqc_post {
    tag "$sample_name"
    // Input: fastq file
    input:
    tuple val(sample_name), path(trimmomatic)
    // Output: quality control report
    output:
    tuple val(sample_name), path("${sample_name}_fastqc.zip"), path("${sample_name}_fastqc.html")   
    // Publish results
    publishDir "${params.outdir}/fastqc_post", mode: 'copy', overwrite: true
    // Script: Run
    script:
    """
    fastqc --threads ${task.cpus} ${trimmomatic}
    """
}