#!/bin/bash -l
#SBATCH --job-name=dl_string_act
#SBATCH --output=/fs/pool/pool-mann-projects/Peter/CKG/logs/dl_string_act_%j.out
#SBATCH --error=/fs/pool/pool-mann-projects/Peter/CKG/logs/dl_string_act_%j.err
#SBATCH --time=02:00:00
#SBATCH --mem=4G
#SBATCH --cpus-per-task=1
#SBATCH --partition=p.hpcl93
#SBATCH --nodes=1

echo "=== Downloading STRING protein.actions v11.0 ==="
echo "Job ID: ${SLURM_JOB_ID}"
echo "Started: $(date)"

BASE_DIR="/fs/pool/pool-mann-projects/Peter/CKG/data/databases/STRING"
mkdir -p ${BASE_DIR}
cd ${BASE_DIR}

# Remove old empty files
rm -f 9606.protein.actions.v11.0.txt.gz 9606.protein.actions.v12.0.txt.gz 2>/dev/null

# STRING protein.actions only exists in v11.0 (not v12.0!)
URL="https://stringdb-downloads.org/download/protein.actions.v11.0/9606.protein.actions.v11.0.txt.gz"
echo "URL: ${URL}"

wget -v --timeout=300 --tries=3 "${URL}" -O 9606.protein.actions.v11.0.txt.gz

if [ -s 9606.protein.actions.v11.0.txt.gz ]; then
    echo "SUCCESS: Downloaded $(ls -lh 9606.protein.actions.v11.0.txt.gz)"
    gunzip -t 9606.protein.actions.v11.0.txt.gz && echo "File integrity OK"
else
    echo "FAILED: File is empty or download failed"
    exit 1
fi

echo "Finished: $(date)"
