#!/bin/bash -l
#SBATCH --job-name=dl_reactome
#SBATCH --output=/fs/pool/pool-mann-projects/Peter/CKG/logs/dl_reactome_%j.out
#SBATCH --error=/fs/pool/pool-mann-projects/Peter/CKG/logs/dl_reactome_%j.err
#SBATCH --time=01:00:00
#SBATCH --mem=4G
#SBATCH --cpus-per-task=1
#SBATCH --partition=p.hpcl93
#SBATCH --nodes=1

echo "=== Downloading Reactome Database ==="
echo "Job ID: ${SLURM_JOB_ID}"
echo "Started: $(date)"

BASE_DIR="/fs/pool/pool-mann-projects/Peter/CKG/data/databases/Reactome"
mkdir -p ${BASE_DIR}
cd ${BASE_DIR}

echo "Downloading Reactome files..."

# Pathways
wget -q --show-progress "https://reactome.org/download/current/ReactomePathways.txt" -O ReactomePathways.txt
echo "ReactomePathways.txt: $(wc -l < ReactomePathways.txt) lines"

# Hierarchy
wget -q --show-progress "https://reactome.org/download/current/ReactomePathwaysRelation.txt" -O ReactomePathwaysRelation.txt
echo "ReactomePathwaysRelation.txt: $(wc -l < ReactomePathwaysRelation.txt) lines"

# Protein to Pathway
wget -q --show-progress "https://reactome.org/download/current/UniProt2Reactome_PE_Pathway.txt" -O UniProt2Reactome_PE_Pathway.txt
echo "UniProt2Reactome_PE_Pathway.txt: $(wc -l < UniProt2Reactome_PE_Pathway.txt) lines"

# Metabolite (ChEBI) to Pathway
wget -q --show-progress "https://reactome.org/download/current/ChEBI2Reactome_PE_Pathway.txt" -O ChEBI2Reactome_PE_Pathway.txt
echo "ChEBI2Reactome_PE_Pathway.txt: $(wc -l < ChEBI2Reactome_PE_Pathway.txt) lines"

echo ""
echo "=== Files downloaded ==="
ls -lh ${BASE_DIR}/*.txt

echo ""
echo "Finished: $(date)"
