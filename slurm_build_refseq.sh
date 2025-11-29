#!/bin/bash -l
#SBATCH --job-name=ckg_refseq
#SBATCH --output=/fs/pool/pool-mann-projects/Peter/CKG/logs/ckg_refseq_%j.out
#SBATCH --error=/fs/pool/pool-mann-projects/Peter/CKG/logs/ckg_refseq_%j.err
#SBATCH --time=02:00:00
#SBATCH --mem=32G
#SBATCH --cpus-per-task=4
#SBATCH --partition=p.hpcl93
#SBATCH --nodes=1

echo "=== Building RefSeq Database (GRCh38.p14) ==="
echo "Job ID: ${SLURM_JOB_ID}"
echo "Started: $(date)"

cd /fs/pool/pool-mann-projects/Peter/CKG
source venv/bin/activate

export PYTHONUNBUFFERED=1

python3 -u << 'PYTHON_SCRIPT'
import sys
import os
import time

sys.stdout = os.fdopen(sys.stdout.fileno(), 'w', buffering=1)

db_dir = '/fs/pool/pool-mann-projects/Peter/CKG/data/databases'
import_dir = '/fs/pool/pool-mann-projects/Peter/CKG/data/imports/databases'

print("Loading RefSeq parser...")
from ckg.graphdb_builder.databases.parsers import refseqParser

print("Running RefSeq parser (download=True for latest GRCh38.p14)...")
start = time.time()
result = refseqParser.parser(db_dir, download=True)
elapsed = time.time() - start

print(f"RefSeq completed in {elapsed:.1f}s")

if result:
    entities, relationships, headers = result

    # Save entities
    for entity_type, data in entities.items():
        filename = f"{entity_type}.tsv"
        header = headers.get(entity_type, [])
        filepath = os.path.join(import_dir, filename)
        with open(filepath, 'w') as f:
            if header:
                f.write('\t'.join(header) + '\n')
            for row in data:
                f.write('\t'.join(str(x) for x in row) + '\n')
        print(f"Saved {len(data)} {entity_type} entries to {filename}")

    # Save relationships
    for rel_type, data in relationships.items():
        filename = f"refseq_{rel_type.lower()}.tsv"
        header = headers.get(rel_type, [])
        filepath = os.path.join(import_dir, filename)
        with open(filepath, 'w') as f:
            if header:
                f.write('\t'.join(header) + '\n')
            for row in data:
                f.write('\t'.join(str(x) for x in row) + '\n')
        print(f"Saved {len(data)} {rel_type} relationships to {filename}")

print("Done!")
PYTHON_SCRIPT

echo ""
echo "=== Output files ==="
ls -lh /fs/pool/pool-mann-projects/Peter/CKG/data/imports/databases/Transcript*.tsv 2>/dev/null
ls -lh /fs/pool/pool-mann-projects/Peter/CKG/data/imports/databases/Chromosome*.tsv 2>/dev/null
ls -lh /fs/pool/pool-mann-projects/Peter/CKG/data/imports/databases/refseq*.tsv 2>/dev/null
echo ""
echo "Finished: $(date)"
