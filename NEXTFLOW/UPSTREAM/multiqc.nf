process multiqc {
    // No input: MultiQC processes do not require input files directly
    // Output: MultiQC report files
    output:
    path("multiqc_report.html")
    path("multiqc_data")
    // Publish MultiQC report to output directory
    publishDir "${params.outdir}/multiqc", mode: 'copy', overwrite: true
    // Script to run MultiQC
    script:
    """
    multiqc ${params.outdir}/fastqc_pre -o ./
    """
}
