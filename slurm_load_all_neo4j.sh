#!/bin/bash -l
#SBATCH --job-name=ckg_fullload
#SBATCH --output=/fs/pool/pool-mann-projects/Peter/CKG/logs/ckg_fullload_%j.out
#SBATCH --error=/fs/pool/pool-mann-projects/Peter/CKG/logs/ckg_fullload_%j.err
#SBATCH --time=24:00:00
#SBATCH --mem=64G
#SBATCH --cpus-per-task=8
#SBATCH --partition=p.hpcl93
#SBATCH --nodes=1

echo "=== Full CKG Data Load into Neo4j ==="
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

from ckg.graphdb_builder.builder import loader
from ckg.graphdb_connector import connector

print("Getting Neo4j driver...")
driver = connector.getGraphDatabaseConnectionConfiguration()

if not driver:
    print("ERROR: Could not connect to Neo4j")
    sys.exit(1)

# Load entities in dependency order
# Each entity is loaded separately for better tracking
load_order = [
    "ontologies",
    "chromosomes",
    "genes",
    "transcripts",
    "proteins",
    "annotations",
    "protein_structure",
    "ppi",
    "pathway",
    "metabolite",
    "jensenlab",
    "mentions",
    "known_variants",
]

for entity in load_order:
    print(f"\n{'='*60}")
    print(f"Loading: {entity}")
    print(f"Time: {time.strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"{'='*60}")
    start = time.time()
    try:
        loader.partialUpdate([entity])
        elapsed = time.time() - start
        print(f"Completed {entity} in {elapsed:.1f}s")
    except Exception as e:
        elapsed = time.time() - start
        print(f"Error loading {entity} after {elapsed:.1f}s: {e}")
        import traceback
        traceback.print_exc()
        continue

print("\n" + "="*60)
print("Data loading complete!")
print(f"Finished: {time.strftime('%Y-%m-%d %H:%M:%S')}")
print("="*60)

# Final stats
print("\nFinal database statistics:")
try:
    result = connector.sendQuery(driver, "MATCH (n) RETURN labels(n)[0] as label, count(*) as count ORDER BY count DESC")
    total = 0
    for record in result:
        print(f"  {record['label']}: {record['count']:,}")
        total += record['count']
    print(f"\nTotal nodes: {total:,}")
except Exception as e:
    print(f"Could not get stats: {e}")

PYTHON_SCRIPT

echo ""
echo "=== Job Complete ==="
echo "Finished: $(date)"
