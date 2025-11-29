#!/bin/bash -l
#SBATCH --job-name=ckg_load
#SBATCH --output=/fs/pool/pool-mann-projects/Peter/CKG/logs/ckg_load_%j.out
#SBATCH --error=/fs/pool/pool-mann-projects/Peter/CKG/logs/ckg_load_%j.err
#SBATCH --time=12:00:00
#SBATCH --mem=32G
#SBATCH --cpus-per-task=4
#SBATCH --partition=p.hpcl93
#SBATCH --nodes=1

echo "=== Loading CKG Data into Neo4j ==="
echo "Job ID: ${SLURM_JOB_ID}"
echo "Started: $(date)"

cd /fs/pool/pool-mann-projects/Peter/CKG
source venv/bin/activate

export PYTHONUNBUFFERED=1

# First, verify Neo4j is accessible
echo "Testing Neo4j connection..."
python3 -c "
from ckg.graphdb_connector import connector
driver = connector.getGraphDatabaseConnectionConfiguration()
if driver:
    print('Neo4j connection successful')
else:
    print('Failed to connect to Neo4j')
    exit(1)
"

if [ $? -ne 0 ]; then
    echo "Cannot connect to Neo4j. Make sure it's running."
    exit 1
fi

echo ""
echo "=== Starting partial data load ==="
echo ""

# Load data in order of dependencies
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

# Define what we want to load based on available data
# Order matters! Dependencies first.
imports_to_load = [
    "ontologies",      # Disease, Tissue, Biological_process, etc.
    "chromosomes",     # Chromosome nodes (from RefSeq)
    "genes",           # Gene nodes (from HGNC.tsv -> Gene.tsv)
    "transcripts",     # Transcript nodes (from RefSeq)
    "proteins",        # Protein, Peptide, Amino_acid_sequence
    "annotations",     # GO annotations
    "protein_structure", # PDB structures
    "ppi",             # STRING, IntAct interactions
    "pathway",         # Reactome pathways
    "metabolite",      # HMDB metabolites
    "jensenlab",       # JensenLab associations
    "mentions",        # Publication mentions
    "known_variants",  # Known variants
]

print(f"Will attempt to load: {', '.join(imports_to_load)}")
print("")

for entity in imports_to_load:
    print(f"\n{'='*60}")
    print(f"Loading: {entity}")
    print(f"{'='*60}")
    start = time.time()
    try:
        loader.partialUpdate([entity])
        elapsed = time.time() - start
        print(f"Completed {entity} in {elapsed:.1f}s")
    except Exception as e:
        elapsed = time.time() - start
        print(f"Error loading {entity} after {elapsed:.1f}s: {e}")
        # Continue with next entity, don't stop
        continue

print("\n" + "="*60)
print("Data loading complete!")
print("="*60)

# Print summary statistics
print("\nQuerying database statistics...")
try:
    result = connector.sendQuery(driver, "MATCH (n) RETURN labels(n)[0] as label, count(*) as count ORDER BY count DESC")
    print("\nNode counts by type:")
    for record in result:
        print(f"  {record['label']}: {record['count']:,}")
except Exception as e:
    print(f"Could not get stats: {e}")

PYTHON_SCRIPT

echo ""
echo "=== Load Complete ==="
echo "Finished: $(date)"
