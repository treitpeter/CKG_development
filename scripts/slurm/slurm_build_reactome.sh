#!/bin/bash -l
#SBATCH --job-name=ckg_reactome
#SBATCH --output=/fs/pool/pool-mann-projects/Peter/CKG/logs/ckg_reactome_%j.out
#SBATCH --error=/fs/pool/pool-mann-projects/Peter/CKG/logs/ckg_reactome_%j.err
#SBATCH --time=01:00:00
#SBATCH --mem=16G
#SBATCH --cpus-per-task=4
#SBATCH --partition=p.hpcl93
#SBATCH --nodes=1

echo "=== Building Reactome Database ==="
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

print("Loading Reactome parser...")
from ckg.graphdb_builder.databases.parsers import reactomeParser

print("Running Reactome parser...")
start = time.time()
result = reactomeParser.parser(db_dir, download=False)
elapsed = time.time() - start

print(f"Reactome completed in {elapsed:.1f}s")

if result:
    entities, relationships, entities_header, relationships_headers = result
    print(f"Entities (pathways): {len(entities)}")

    # Save entities (pathways)
    with open(os.path.join(import_dir, "Reactome_Pathway.tsv"), 'w') as f:
        f.write('\t'.join(entities_header) + '\n')
        for entity in entities:
            f.write('\t'.join(str(x) for x in entity) + '\n')
    print(f"Saved {len(entities)} pathways")

    # Save relationships
    for (rel_type, rel_name), rels in relationships.items():
        filename = f"Reactome_{rel_type}_{rel_name}.tsv"
        header = relationships_headers.get(rel_type, [])
        with open(os.path.join(import_dir, filename), 'w') as f:
            if header:
                f.write('\t'.join(header) + '\n')
            for rel in rels:
                f.write('\t'.join(str(x) for x in rel) + '\n')
        print(f"Saved {len(rels)} {rel_type} {rel_name} relationships")

print("Done!")
PYTHON_SCRIPT

echo ""
echo "=== Output files ==="
ls -lh /fs/pool/pool-mann-projects/Peter/CKG/data/imports/databases/Reactome*.tsv 2>/dev/null
echo ""
echo "Finished: $(date)"
