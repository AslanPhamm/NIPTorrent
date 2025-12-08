#!/usr/bin/env nextflow
// Include downstream modules
include { convert_files }      from "./DOWNSTREAM/convert_files.nf"
include { read_count }         from "./DOWNSTREAM/read_count.nf"
include { pca_plot }           from "./DOWNSTREAM/PCA_plot.nf"
include { convert_gender}      from "./DOWNSTREAM/convert_gender.nf"
include { defrag_a }           from "./DOWNSTREAM/defrag_a.nf"
include { defrag_b }           from "./DOWNSTREAM/defrag_b.nf"
include { seqff }              from "./DOWNSTREAM/seqff.nf"
include { wisecondorX }        from "./DOWNSTREAM/wisecondorX.nf"
include { report }             from "./DOWNSTREAM/report_NIPT.nf"
include { combine as combine_defrag_b }         from "./DOWNSTREAM/combine.nf"
include { combine as combine_seqff }            from "./DOWNSTREAM/combine.nf"

output_dir = params.output_dir
workflow {
// -----------------------------
// Load BAM and BAI
// -----------------------------
    Channel .fromPath(params.input_csv)
            .splitCsv(header: true)
            .map { row ->
                def sample = row.sample
                def bam = file(row.bam)
                def bai = row.bai ? file(row.bai) : file("${row.bam}.bai")
                tuple(sample, bam, bai)
            }
            .set { bam_input }
    // Input: Channel: Collect bam and bai files
    bam_files = bam_input.map { sample, bam, bai -> bam }
    bam_index = bam_input.map { sample, bam, bai -> bai }
    bam_list = bam_files.mix(bam_index).collect()
// //    
    Channel
        .fromPath("${params.reference_dir}/boydir")
        .set { boy_dir } 
    Channel
        .fromPath("${params.reference_dir}/girldir")
        .set { girl_dir }
    Channel
        .fromPath("${params.reference_dir}/wisecondorx_reference.npz")
        .set { ref_npz }
// //
    // Convert bam file to .gcc, .pickle, .npz
    convert_files (bam_input, output_dir)  
    converted_results_cluster = convert_files.out.gcc
            .combine(convert_files.out.pickle, by:0)
            .combine(convert_files.out.npz, by:0)
// //
    // Calculate read counts
    read_count_results = read_count (bam_list)
// //
    //PCA plot
    pca_plot_results = pca_plot (
        converted_results_cluster.map { it[1] }.collect(),
        converted_results_cluster.map { it[2] }.collect()
    )
// //
    // Predict gender
    convert_gender (bam_list, output_dir)

    gender_csv = convert_gender.out.gender_prediction
// //
    // Predict ff male gender (defrag_a)
    defrag_a (
        boy_dir,
        girl_dir,
        converted_results_cluster.map { it[1] }.collect(),
        converted_results_cluster.map { it[2] }.collect()
    )
// //
    // Predict ff male gender (defrag_b)
    defrag_b_inputs = boy_dir
        .combine(girl_dir)
        .combine(converted_results_cluster)
        .map { boy, girl, sample, gcc, pickle, npz ->
            tuple(boy, girl, gcc, pickle)
        }
    defrag_b(
        defrag_b_inputs,
        gender_csv
    )
    combine_defrag_b(
        defrag_b.out.tsv,
        "defrag_b_summary.csv",
        "${params.outdir}/defrag_b"
    )
// //
    // Predict ff all chromosomes (seqff)
    seqff(bam_input)
    combine_seqff(
        seqff.out.tsv,
        "seqff_summary.csv",
        "${params.outdir}/seqff"
    )
// //
    // WisecondorX
    abnormal_results = wisecondorX (
        converted_results_cluster.map { it[3] }.collect(),
        ref_npz
    )
// //
//     // Report
//     report (
//         read_count_results.tsv,
//         pca_plot_results.tsv,
//         gender_csv,
//         seqff_results.csv,
//         abnormal_results.tsv,
//         abnormal_results.abnormal_results,
//         abnormal_results.plot_tsv
//     )
}
