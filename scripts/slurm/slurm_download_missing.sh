#!/bin/bash -l
#SBATCH --job-name=ckg_download
#SBATCH --output=/fs/pool/pool-mann-projects/Peter/CKG/logs/ckg_download_%j.out
#SBATCH --error=/fs/pool/pool-mann-projects/Peter/CKG/logs/ckg_download_%j.err
#SBATCH --time=04:00:00
#SBATCH --mem=8G
#SBATCH --cpus-per-task=2
#SBATCH --partition=p.hpcl93
#SBATCH --nodes=1

echo "======================================"
echo "Downloading Missing CKG Databases"
echo "======================================"
echo "Job ID: ${SLURM_JOB_ID}"
echo "Started: $(date)"
echo "======================================"

BASE_DIR="/fs/pool/pool-mann-projects/Peter/CKG/data/databases"

# STRING Database v12.0 (latest 2024)
echo ""
echo "=== STRING v12.0 ==="
mkdir -p ${BASE_DIR}/STRING
cd ${BASE_DIR}/STRING
wget -q --show-progress "https://stringdb-downloads.org/download/protein.aliases.v12.0/9606.protein.aliases.v12.0.txt.gz" -O 9606.protein.aliases.v12.0.txt.gz
wget -q --show-progress "https://stringdb-downloads.org/download/protein.links.detailed.v12.0/9606.protein.links.detailed.v12.0.txt.gz" -O 9606.protein.links.detailed.v12.0.txt.gz
wget -q --show-progress "https://stringdb-downloads.org/download/protein.actions.v12.0/9606.protein.actions.v12.0.txt.gz" -O 9606.protein.actions.v12.0.txt.gz
echo "STRING files:"
ls -lh ${BASE_DIR}/STRING/

# IntAct Database
echo ""
echo "=== IntAct ==="
mkdir -p ${BASE_DIR}/Intact
cd ${BASE_DIR}/Intact
wget --no-passive-ftp "https://ftp.ebi.ac.uk/pub/databases/intact/current/psimitab/intact.txt" -O intact.txt
echo "IntAct files:"
ls -lh ${BASE_DIR}/Intact/

# HGNC (Gene Names) - Now hosted on Google Cloud Storage
echo ""
echo "=== HGNC ==="
mkdir -p ${BASE_DIR}/HGNC
cd ${BASE_DIR}/HGNC
wget -q --show-progress "https://storage.googleapis.com/public-download-files/hgnc/tsv/tsv/hgnc_complete_set.txt" -O hgnc_complete_set.txt
echo "HGNC files:"
ls -lh ${BASE_DIR}/HGNC/

# GWAS Catalog
echo ""
echo "=== GWAS Catalog ==="
mkdir -p ${BASE_DIR}/GWAScatalog
cd ${BASE_DIR}/GWAScatalog
wget -q --show-progress "https://www.ebi.ac.uk/gwas/api/search/downloads/alternative" -O gwas_catalog.tsv
echo "GWAS files:"
ls -lh ${BASE_DIR}/GWAScatalog/

echo ""
echo "======================================"
echo "All Downloads Complete"
echo "======================================"
echo "Summary:"
for db in STRING Intact HGNC GWAScatalog; do
    count=$(ls ${BASE_DIR}/${db}/ 2>/dev/null | wc -l)
    size=$(du -sh ${BASE_DIR}/${db}/ 2>/dev/null | cut -f1)
    echo "  ${db}: ${count} files, ${size}"
done

echo ""
echo "Finished: $(date)"
