#!/usr/bin/env nextflow
// Include downstream modules
include { convert_files }                from "./DOWNSTREAM/convert_files.nf"
include { read_count }                   from "./DOWNSTREAM/read_count.nf"
include { pca_plot }                     from "./DOWNSTREAM/PCA_plot.nf"
include { gender}                        from "./DOWNSTREAM/gender.nf"
include { ref }                          from "./DOWNSTREAM/create_ref.nf"
include { defrag_a }                    from "./DOWNSTREAM/defrag_a.nf"
include { defrag_b }                    from "./DOWNSTREAM/defrag_b.nf"
include { seqff }                       from "./DOWNSTREAM/seqff.nf"
include { wisecondorX }                   from "./DOWNSTREAM/wisecondorX.nf"
include { report }                       from "./DOWNSTREAM/report_NIPT.nf"

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
//        
        Channel
            .fromPath("${params.reference_dir}/boydir")
            .set { boy_dir } 
        Channel
            .fromPath("${params.reference_dir}/girldir")
            .set { girl_dir }
        Channel
            .fromPath("${params.reference_dir}/wisecondorx_reference.npz")
            .set { ref_npz }

        // Convert bam file to .gcc, .pickle, .npz
        convert_files (bam_input, "${params.output_dir}")  
        .set { converted_files }
// 
        // Calculate read counts
        read_count (bam_list, "${params.output_dir}")

// 
        //PCA plot
        pca_plot (
            converted_files.gcc,
            converted_files.pickle
        )
// 
        // Predict gender
        convert_gender (bam_list, "${params.output_dir}")
        gender_csv = convert_gender.out.gender_prediction
//
        // Predict ff male gender (defrag)
        defrag_a (
            boy_dir,
            girl_dir,
            converted_files.gcc,
            converted_files.pickle
        )

        defrag_b (
            boy_dir,
            girl_dir,
            converted_files.gcc,
            converted_files.pickle
            gender_csv
        )
//
        // Predict ff all chromosomes (seqff)
        seqff (bam_files)
        ff_all.csv.view { "Predicted fetal fraction of all chromosomes in file ${it}." }
//
        // Predict abnormal
        abnormal_results = wisecondorX (
            converted_files.npz,
            ref_npz
        )
// 
        // Report
        report (
            read_count.tsv,
            pca_plot.tsv,
            gender_csv,
            seqff.csv,
            abnormal_results.tsv,
            abnormal_results.abnormal_results,
            abnormal_results.plot_tsv
        )
}
