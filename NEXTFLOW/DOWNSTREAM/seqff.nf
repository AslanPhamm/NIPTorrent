// process ff_all {
//     // Calculate read counts from BAM files
//     input:
//     path bam_list, stageAs:"bam_list/*"
//     // Output channels
//     output:
//     path "seqff.tsv", emit: tsv
//     // Publish results
//     publishDir "${params.outdir}/seqff", mode: 'copy'

//     script:
//     """
//      # Set up a safe temporary directory for R/Python tools
//     export TMPDIR=\$(mktemp -d)
//     echo "TMPDIR is set to \$TMPDIR"
    
//     for file in bam_list/*.bam; do
//         echo \$file >> bam_file.txt
//     done

//     seqff.py bam_file.txt
//     """
// }
process ff_all {
    input:
    tuple val(sample_name), path(mapped_bam)

    output:
    tuple val(sample_name), path("${sample_name}.tsv")

    publishDir("${params.outdir}/seqff", mode: 'copy', overwrite: true)

    script:
    """
    Rscript ${params.seqff_dir}/seqff.r ${mapped_bam} ${params.seqff_dir} > ${sample_name}.tsv
    """
}

