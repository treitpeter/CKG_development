#!/bin/bash -l
#SBATCH --job-name=ckg_string
#SBATCH --output=/fs/pool/pool-mann-projects/Peter/CKG/logs/ckg_string_%j.out
#SBATCH --error=/fs/pool/pool-mann-projects/Peter/CKG/logs/ckg_string_%j.err
#SBATCH --time=02:00:00
#SBATCH --mem=32G
#SBATCH --cpus-per-task=4
#SBATCH --partition=p.hpcl93
#SBATCH --nodes=1

echo "=== Building STRING Database ==="
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

print("Loading STRING parser...")
from ckg.graphdb_builder.databases.parsers import stringParser

print("Running STRING parser...")
start = time.time()
mapping, drugmapping = stringParser.parser(db_dir, import_dir, drug_source=None, download=False, db="STRING")
elapsed = time.time() - start

print(f"STRING completed in {elapsed:.1f}s")
print(f"Mapping entries: {len(mapping)}")

# Check output file
output_file = os.path.join(import_dir, "string_interacts_with.tsv")
if os.path.exists(output_file):
    with open(output_file, 'r') as f:
        lines = sum(1 for _ in f)
    size = os.path.getsize(output_file)
    print(f"Output: {output_file}")
    print(f"Lines: {lines}, Size: {size/1024/1024:.1f}MB")
else:
    print("ERROR: Output file not created!")

print("Done!")
PYTHON_SCRIPT

echo ""
echo "=== Output files ==="
ls -lh /fs/pool/pool-mann-projects/Peter/CKG/data/imports/databases/string*.tsv 2>/dev/null
echo ""
echo "Finished: $(date)"
