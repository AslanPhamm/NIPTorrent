#!/usr/bin/env nextflow

// Include upstream modules
include { convert_fastq }                from "./UPSTREAM/samtools/fastq.nf"
include { fastqc_pre }                   from "./UPSTREAM/fastqc_pre.nf"
include { multiqc }                      from "./UPSTREAM/multiqc.nf"
include { trimmomatic }                  from "./UPSTREAM/trimmomatic.nf"
include { fastqc_post }                  from "./UPSTREAM/fastqc_post.nf"
include { bwa }                          from "./UPSTREAM/bwa.nf"
include { sort_bam }                     from "./UPSTREAM/samtools/sort_bam.nf"
include { rm_dup }                       from "./UPSTREAM/samtools/rm_dup.nf"
include { mapped_bam }                   from "./UPSTREAM/samtools/mapped_bam.nf"
include { index }                        from "./UPSTREAM/samtools/index.nf"
// Include downstream modules
include { convert_files as convert_run } from "./DOWNSTREAM/convert_files.nf"
include { convert_files as convert_ref } from "./DOWNSTREAM/convert_files.nf"
include { read_count }                   from "./DOWNSTREAM/read_count.nf"
include { pca_plot }                     from "./DOWNSTREAM/PCA_plot.nf"
include { gender as gender_run }         from "./DOWNSTREAM/gender.nf"
include { gender as gender_ref }         from "./DOWNSTREAM/gender.nf"
include { ref }                          from "./DOWNSTREAM/create_ref.nf"
include { ff_male }                      from "./DOWNSTREAM/defrag.nf"
include { ff_all }                       from "./DOWNSTREAM/seqff.nf"
include { wisecondor }                   from "./DOWNSTREAM/wisecondor.nf"
include { report }                       from "./DOWNSTREAM/report_NIPT.nf"

workflow {
    // Define input channels
// Input CSV: sample_id, path(read)
    // Channel
    //     .fromPath(params.input_csv)
    //     .splitCsv(header: true)
    //     .map { row -> tuple(row.sample, row.read) }
    //     .set { bam_input }
//
    // UPSTREAM processes

    // fastq = convert_fastq(bam_input)
    // // fastqc_pre = fastqc_pre(fastq)
    // // multiqc = multiqc()
    // trimmed_fastq = trimmomatic(fastq)
    // // fastqc_post = fastqc_post(trimmed_fastq)
    // aligned_bam   = bwa(bam_input)
    // sorted_bam    = sort_bam(aligned_bam)
    // dedup_bam     = rm_dup(sorted_bam)
    // mapped_bam    = mapped_bam(dedup_bam)
    // indexed_bam   = index(mapped_bam)

    // DOWNSTREAM processes
// CREATE REFERENCE
    mapped_bam = Channel
        .fromPath(params.input_csv)
        .splitCsv(header: true)
        .map { row -> tuple(row.sample_name, file(row.bam_path)) }

    indexed_bam = Channel
        .fromPath(params.input_csv)
        .splitCsv(header: true)
        .map { row -> tuple(row.sample_name, file(row.bai_path)) }
    // Input: Channel: Collect bam files
    if (params.create_ref) {
        bam_file = mapped_bam.map { sample_name, bam -> bam }.view()
        bam_index = indexed_bam.map { sample, bam -> bam }.view()
        bam_list = bam_file.mix(bam_index).collect()
        // Convert bam file to .gcc, .pickle, .npz
        converted_results = convert_ref (bam_list, "ref_sample")
// 
        // Print completion message
        converted_results.gcc.view { "Converted bamfile: ${it}" }
        converted_results.pickle.view { "Converted bamfile: ${it}" }
        converted_results.npz.view { "Converted bamfile: ${it}" }
// 
        // Predict gender
        gender_results = gender_ref (bam_list, "ref_sample")
        gender_results.csv.view { "Prediction gender ${it}" }
// 
        // Create reference
        create_ref_results = ref (
            converted_results.gcc,
            converted_results.pickle,
            converted_results.npz,
            gender_results.csv
        )
        create_ref_results.npz.view { "Create reference successfully with file ${it}." }
    }


// RUN SAMPLE
    // mapped_bam = Channel
    //     .fromPath(params.input_csv)
    //     .splitCsv(header: true)
    //     .map { row -> tuple(row.sample_name, file(row.bam_path)) }

    // indexed_bam = Channel
    //     .fromPath(params.input_csv)
    //     .splitCsv(header: true)
    //     .map { row -> tuple(row.sample_name, file(row.bai_path)) }
    // Input: Channel: Collect bam files
    if (params.run_sample) {
        bam_file = mapped_bam.map { sample_name, bam -> bam }.view()
        bam_index = indexed_bam.map { sample, bam -> bam }.view()
        bam_list = bam_file.mix(bam_index).collect()
//        
        Channel
            .fromPath('./ref1_results/reference/boydir')
            .set { boy_dir } 
        Channel
            .fromPath('./ref1_results/reference/girldir')
            .set { girl_dir }
        Channel
            .fromPath('./ref1_results/reference/wisecondorx_reference.npz')
            .set { ref_npz }
        // Convert bam file to .gcc, .pickle, .npz
        converted_results = convert_run (bam_list, "run_sample")
// 
        // Print completion message
        converted_results.gcc.view { "Converted bamfile: ${it}" }
        converted_results.pickle.view { "Converted bamfile: ${it}" }
        converted_results.npz.view { "Converted bamfile: ${it}" }
// 
        // Calculate read counts
        read_count_results = read_count (bam_list)
        read_count_results.tsv.view { "Readcount done." }
// 
        //PCA plot
        pca_plot = pca_plot (
            converted_results.gcc,
            converted_results.pickle
        )
// 
        // Predict gender
        gender_results = gender_run (bam_list, "run_sample")
        gender_results.csv.view { "Prediction gender ${it}" }
//
        // Predict male gender (ff)
        ff_male = ff_male (
            boy_dir,
            girl_dir,
            converted_results.gcc,
            converted_results.pickle
        )
        ff_male.view { "Predicted fetal fraction of male samples in file ${it}." }
//
        // // Predict all chromosomes (ff)
        // ff_all = ff_all(mapped_bam)
        // ff_all.view { "Predicted fetal fraction of all chromosomes in file ${it}." }

        // Predict abnormal
        abnormal_results = wisecondor (
            converted_results.npz,
            ref_npz
        )
// 
        //Report
        // report = report (
        //     read_count_results.tsv,
        //     pca_plot.tsv,
        //     gender_results.csv,
        //     seqff.csv,
        //     abnormal_results.tsv,
        //     abnormal_results.abnormal_results,
        //     abnormal_results.plot_tsv

        // )
    } 
}
