#!/bin/bash -l
#SBATCH --job-name=ckg_proteins
#SBATCH --output=/fs/pool/pool-mann-projects/Peter/CKG/logs/ckg_proteins_%j.out
#SBATCH --error=/fs/pool/pool-mann-projects/Peter/CKG/logs/ckg_proteins_%j.err
#SBATCH --time=06:00:00
#SBATCH --mem=100G
#SBATCH --cpus-per-task=8
#SBATCH --partition=p.hpcl93
#SBATCH --nodes=1

echo "======================================"
echo "CKG Protein Data Build (UniProt 2025)"
echo "======================================"
echo "Job ID: $SLURM_JOB_ID"
echo "Node: $(hostname)"
echo "Started: $(date)"
echo "Memory: 100GB"
echo "======================================"

cd /fs/pool/pool-mann-projects/Peter/CKG
source venv/bin/activate

python -c "
from ckg.graphdb_builder.databases.parsers import uniprotParser
import os

db_dir = '/fs/pool/pool-mann-projects/Peter/CKG/data/databases'
import_dir = '/fs/pool/pool-mann-projects/Peter/CKG/data/imports/databases'

print('Running UniProt parser with fresh 2025 data...')
print('Processing proteins, peptides, variants, GO annotations...')

try:
    stats = uniprotParser.parser(db_dir, import_dir, download=False)
    print()
    print('='*60)
    print('COMPLETED!')
    print('='*60)
    for s in sorted(stats, key=lambda x: str(x)):
        print(f'  {s}')
except Exception as e:
    print(f'Error: {type(e).__name__}: {e}')
    import traceback
    traceback.print_exc()
    exit(1)
"

echo ""
echo "Output files:"
ls -la /fs/pool/pool-mann-projects/Peter/CKG/data/imports/databases/Protein*.tsv 2>/dev/null
ls -la /fs/pool/pool-mann-projects/Peter/CKG/data/imports/databases/Peptide*.tsv 2>/dev/null

echo ""
echo "Finished: $(date)"
