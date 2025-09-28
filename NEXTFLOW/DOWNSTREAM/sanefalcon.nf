process sanefalcon_ref {
    tag "Extract start positions from BAM: ${bam_file.getBaseName()}"

    input:
    tuple val(sample), path(bam_file)

    output:
    tuple val(sample), path("${sample}.start"), emit: start_files

    script:
    """
    mkdir -p sanefalcon_ref/${sample}
    ./scripts/prepSamples.sh ${bam_file} sanefalcon_ref/${sample}
    
    # Combine and rename output to a single reference to the sample start directory
    touch ${sample}.start
    find sanefalcon_ref/${sample} -name "*.start.*" >> ${sample}.start
    """
}