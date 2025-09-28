#!/bin/bash
#SBATCH --job-name=bash
#SBATCH --output=/mnt/data20tb/NIPT_IONTOR_PHUONGCHAU/train/logs/bam2trimqc_%j.out
#SBATCH --error=/mnt/data20tb/NIPT_IONTOR_PHUONGCHAU/train/logs/bam2trimqc_%j.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=256G
#SBATCH --time=2-00:00:00
# Take input
fastq_dir="/mnt/data20tb/NIPT_IONTOR_PHUONGCHAU/REF/fastq"
# Output
output=$fastq_dir/"sample.csv"
# Create header of .csv file
echo "sample,read" > $output

# For loop to get sample:
for read in $fastq_dir/*.fastq; do
    sample_name=$(basename $read ".fastq")
    echo "$sample_name,$read" >> $output
done

echo "CSV file created at: $output."
# Run the Nextflow pipeline
nextflow run main.nf \
    --input_csv /mnt/data20tb/NIPT_IONTOR_PHUONGCHAU/REF/fastq/sample.csv \
    --outdir /mnt/data20tb/NIPT_IONTOR_PHUONGCHAU/NIPTorrent/ref3_results \
    --create_ref false \
    --run_sample true 
