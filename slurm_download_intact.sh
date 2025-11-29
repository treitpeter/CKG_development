#!/bin/bash -l
#SBATCH --job-name=dl_intact
#SBATCH --output=/fs/pool/pool-mann-projects/Peter/CKG/logs/dl_intact_%j.out
#SBATCH --error=/fs/pool/pool-mann-projects/Peter/CKG/logs/dl_intact_%j.err
#SBATCH --time=04:00:00
#SBATCH --mem=4G
#SBATCH --cpus-per-task=1
#SBATCH --partition=p.hpcl93
#SBATCH --nodes=1

echo "=== Downloading IntAct Database ==="
echo "Job ID: ${SLURM_JOB_ID}"
echo "Started: $(date)"

BASE_DIR="/fs/pool/pool-mann-projects/Peter/CKG/data/databases/Intact"
mkdir -p ${BASE_DIR}
cd ${BASE_DIR}

# IntAct - protein-protein interactions from EBI
# File is ~10GB, contains PSI-MI TAB format interactions
URL="https://ftp.ebi.ac.uk/pub/databases/intact/current/psimitab/intact.txt"
echo "URL: ${URL}"

wget -v --timeout=600 --tries=3 "${URL}" -O intact.txt

if [ -s intact.txt ]; then
    echo "SUCCESS: Downloaded $(ls -lh intact.txt)"
    echo "Line count: $(wc -l < intact.txt)"
else
    echo "FAILED: File is empty or download failed"
    exit 1
fi

echo "Finished: $(date)"
