#!/bin/bash -l
#SBATCH --job-name=dl_hmdb
#SBATCH --output=/fs/pool/pool-mann-projects/Peter/CKG/logs/dl_hmdb_%j.out
#SBATCH --error=/fs/pool/pool-mann-projects/Peter/CKG/logs/dl_hmdb_%j.err
#SBATCH --time=04:00:00
#SBATCH --mem=8G
#SBATCH --cpus-per-task=2
#SBATCH --partition=p.hpcl93
#SBATCH --nodes=1

echo "=== Downloading HMDB (Human Metabolome Database) ==="
echo "Job ID: ${SLURM_JOB_ID}"
echo "Started: $(date)"

BASE_DIR="/fs/pool/pool-mann-projects/Peter/CKG/data/databases/HMDB"
mkdir -p ${BASE_DIR}
cd ${BASE_DIR}

# HMDB - Human Metabolome Database
# Contains metabolite information including structures, pathways, diseases
URL="https://hmdb.ca/system/downloads/current/hmdb_metabolites.zip"
echo "URL: ${URL}"

wget -v --timeout=600 --tries=3 "${URL}" -O hmdb_metabolites.zip

if [ -s hmdb_metabolites.zip ]; then
    echo "SUCCESS: Downloaded $(ls -lh hmdb_metabolites.zip)"
    echo "Extracting..."
    unzip -o hmdb_metabolites.zip
    ls -lh ${BASE_DIR}/
else
    echo "FAILED: File is empty or download failed"
    exit 1
fi

echo "Finished: $(date)"
