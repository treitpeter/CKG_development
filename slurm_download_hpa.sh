#!/bin/bash -l
#SBATCH --job-name=dl_hpa
#SBATCH --output=/fs/pool/pool-mann-projects/Peter/CKG/logs/dl_hpa_%j.out
#SBATCH --error=/fs/pool/pool-mann-projects/Peter/CKG/logs/dl_hpa_%j.err
#SBATCH --time=02:00:00
#SBATCH --mem=4G
#SBATCH --cpus-per-task=1
#SBATCH --partition=p.hpcl93
#SBATCH --nodes=1

echo "=== Downloading Human Protein Atlas (HPA) ==="
echo "Job ID: ${SLURM_JOB_ID}"
echo "Started: $(date)"

BASE_DIR="/fs/pool/pool-mann-projects/Peter/CKG/data/databases/HPA"
mkdir -p ${BASE_DIR}
cd ${BASE_DIR}

# HPA - Human Protein Atlas
# Contains tissue expression, subcellular localization, pathology data
URL="https://www.proteinatlas.org/download/proteinatlas.tsv.zip"
echo "URL: ${URL}"

wget -v --timeout=300 --tries=3 "${URL}" -O proteinatlas.tsv.zip

if [ -s proteinatlas.tsv.zip ]; then
    echo "SUCCESS: Downloaded $(ls -lh proteinatlas.tsv.zip)"
    echo "Extracting..."
    unzip -o proteinatlas.tsv.zip
    ls -lh ${BASE_DIR}/
else
    echo "FAILED: File is empty or download failed"
    exit 1
fi

echo "Finished: $(date)"
