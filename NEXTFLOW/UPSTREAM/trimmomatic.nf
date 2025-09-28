process trimmomatic {
    tag "$sample_name"
    // Input: fastq file
    input:
    tuple val(sample_name), path(convert_fastq)
    // Output: trimmed fastq file
    output:
    tuple val(sample_name), path("${sample_name}_trim.fastq")
    // Publish results
    publishDir "${params.outdir}/trimmed", mode: 'copy', overwrite: true
    // Script: Run
    script:
    """
    trimmomatic SE -threads ${task.cpus} \
    "${convert_fastq}" "${sample_name}_trim.fastq" \
    SLIDINGWINDOW:10:15 MINLEN:50
    rm "${convert_fastq}"
    """
}
   // trimmomatic SE -threads ${task.cpus} \
    // ${convert_fastq} ${sample_name}.fastq \
    // MINLEN:50
    // rm ${convert_fastq}