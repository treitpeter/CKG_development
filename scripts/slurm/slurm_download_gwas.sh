#!/bin/bash -l
#SBATCH --job-name=dl_gwas
#SBATCH --output=/fs/pool/pool-mann-projects/Peter/CKG/logs/dl_gwas_%j.out
#SBATCH --error=/fs/pool/pool-mann-projects/Peter/CKG/logs/dl_gwas_%j.err
#SBATCH --time=02:00:00
#SBATCH --mem=4G
#SBATCH --cpus-per-task=1
#SBATCH --partition=p.hpcl93
#SBATCH --nodes=1

echo "=== Downloading GWAS Catalog ==="
echo "Job ID: ${SLURM_JOB_ID}"
echo "Started: $(date)"

BASE_DIR="/fs/pool/pool-mann-projects/Peter/CKG/data/databases/GWAScatalog"
mkdir -p ${BASE_DIR}
cd ${BASE_DIR}

# Remove old empty files
rm -f gwas_catalog.tsv gwas-catalog-associations*.zip 2>/dev/null

# GWAS Catalog - use FTP release (more reliable than API)
URL="https://ftp.ebi.ac.uk/pub/databases/gwas/releases/latest/gwas-catalog-associations_ontology-annotated-full.zip"
echo "URL: ${URL}"

wget -v --timeout=300 --tries=3 "${URL}" -O gwas-catalog-associations.zip

if [ -s gwas-catalog-associations.zip ]; then
    echo "SUCCESS: Downloaded $(ls -lh gwas-catalog-associations.zip)"
    unzip -l gwas-catalog-associations.zip
    unzip -o gwas-catalog-associations.zip
    ls -lh ${BASE_DIR}/
else
    echo "FAILED: File is empty or download failed"
    exit 1
fi

echo "Finished: $(date)"
