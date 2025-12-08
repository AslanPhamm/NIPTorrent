#!/bin/bash
#SBATCH --job-name=bash
#SBATCH --output=/mnt/d18t/DANPHAM/NIPT/NIPTorrent/NEXTFLOW/logs/output_%j.out
#SBATCH --error=/mnt/d18t/DANPHAM/NIPT/NIPTorrent/NEXTFLOW/logs/error_%j.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=40
#SBATCH --mem=100G
#SBATCH --time=2-00:00:00
#---------------------------------------#
##TAKE INPUT##
#---------------------------------------#
# Input directory
MAP_dir="/mnt/d18t/DANPHAM/NIPT/NIPT_DATA/REF/RESULT/TRIM_15_50/mapped"

# Output CSV
output="$MAP_dir/sample.csv"

# Create header
echo "sample,bam,bai" > "$output"

# Loop through all BAM files
for bam in "$MAP_dir"/*.bam; do
    # Extract sample name (remove .bam)
    sample_name=$(basename "$bam" .bam)

    # Detect index file automatically
    bai="$MAP_dir/${sample_name}.bam.bai"

    # If bai does not exist, try alternative name
    if [[ ! -f "$bai" ]]; then
        bai="$MAP_dir/${sample_name}.bai"
    fi

    # Print warning if bai is missing
    if [[ ! -f "$bai" ]]; then
        echo "WARNING: No BAI found for $sample_name" >&2
        bai=""
    fi
    # Write to CSV
    echo "$sample_name,$bam,$bai" >> "$output"
done
#---------------------------------------#
# RUN NEXTFLOW PIPELINE
#---------------------------------------#
nextflow run main.nf \
    --input_csv $output \
    --outdir /mnt/d18t/DANPHAM/NIPT/NIPT_DATA/TEST/RESULTS/200_samples \
    --reference_dir /mnt/d18t/DANPHAM/NIPT/WORK/reference/REF_200/TRIM_15_50/reference \
    --gender_threshold 0.035 \
    2>&1 | tee "/mnt/d18t/DANPHAM/NIPT/NIPT_DATA/TEST/RESULTS/200_samples/bam.log"