process seqff {
    // Calculate read counts from BAM files
    input:
    path bam_files, stageAs:"bam_files/*"
    // Output channels
    output:
    path "ff_all.tsv", emit: tsv
    path "seqff.csv", emit: csv
    // Publish results
    publishDir "${params.output_dir}/seqff", mode: 'copy'

    script:
    """
    # Set up a safe temporary directory for R/Python tools
    export TMPDIR=\$(mktemp -d)
    for file in bam_files/*.bam; do
        echo \$file >> bam_file.txt
    done
    ${projectDir}/bin/seqff.py bam_file.txt
        python - <<'PY'
import csv

with open('ff_all.tsv', newline='') as tsv_file, open('seqff.csv', 'w', newline='') as csv_file:
    reader = csv.reader(tsv_file, delimiter='\t')
    writer = csv.writer(csv_file)
    writer.writerows(reader)
PY
    """
}

