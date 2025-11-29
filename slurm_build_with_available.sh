#!/bin/bash -l
#SBATCH --job-name=ckg_build
#SBATCH --output=/fs/gpfs41/lv12/fileset02/pool/pool-mann-projects/Peter/CKG/logs/ckg_build_%j.out
#SBATCH --error=/fs/gpfs41/lv12/fileset02/pool/pool-mann-projects/Peter/CKG/logs/ckg_build_%j.err
#SBATCH --time=24:00:00
#SBATCH --mem=128G
#SBATCH --partition=p.hpcl93
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8

echo "======================================"
echo "CKG Database Build - Using Available Data"
echo "======================================"
echo "Job ID: ${SLURM_JOB_ID}"
echo "Node: ${HOSTNAME}"
echo "Started: $(date)"
echo "======================================"

CKG_DIR="/fs/gpfs41/lv12/fileset02/pool/pool-mann-projects/Peter/CKG"
cd ${CKG_DIR}

source ${CKG_DIR}/venv/bin/activate
export PYTHONPATH=${CKG_DIR}

mkdir -p ${CKG_DIR}/logs

echo ""
echo "Available databases:"
ls -1 ${CKG_DIR}/data/databases/
echo ""

python3 -u << 'PYEOF'
import os
import sys
import traceback
from datetime import datetime

sys.path.insert(0, '/fs/gpfs41/lv12/fileset02/pool/pool-mann-projects/Peter/CKG')
os.chdir('/fs/gpfs41/lv12/fileset02/pool/pool-mann-projects/Peter/CKG')

from ckg import ckg_utils
from ckg.graphdb_builder import builder_utils
from ckg.graphdb_builder.ontologies import ontologies_controller as oh
from ckg.graphdb_builder.databases import databases_controller as dh
from ckg.graphdb_builder.builder import loader

print("=" * 50)
print("Loading CKG configuration...")
print("=" * 50)

ckg_config = ckg_utils.read_ckg_config()
log_config = ckg_config['graphdb_builder_log']
logger = builder_utils.setup_logging(log_config, key="available_builder")
dbconfig = builder_utils.setup_config('databases')
oconfig = builder_utils.setup_config('ontologies')

databases_dir = ckg_config['databases_directory']
imports_dir = ckg_config['imports_databases_directory']
ontologies_dir = ckg_config['ontologies_directory']
imports_ontologies_dir = ckg_config['imports_ontologies_directory']

# All possible databases - will skip if not available
ALL_DATABASES = [
    "HGNC", "RefSeq", "CORUM", "SIGNOR", "DGIdb",
    "SIDER", "PhosphoSitePlus", "GWASCatalog", "MutationDs", "Pfam",
    "FooDB", "Exposome Explorer", "SMPDB", "DrugBank", "HMDB",
    "Reactome", "PathwayCommons", "HPA", "IntAct", "DisGEnet",
    "Jensenlab", "Mentions", "UniProt", "STRING", "STITCH",
    # Skip these - need special handling or auth:
    # "OncoKB", "CancerGenomeInterpreter"
]

ALL_ONTOLOGIES = [
    "Amino_acid", "Clinical_variable", "Disease", "Drug",
    "Experimental_factor", "Food", "Gene_ontology", "Modification",
    "Pathway", "Phenotype", "Publication", "Tissue", "Units",
]

successes = []
failures = []
skipped = []

# Step 1: Build ontologies
print("\n" + "=" * 50)
print("STEP 1: Building Ontologies")
print("=" * 50)

try:
    print(f"\n>>> Processing all ontologies...")
    stats = oh.generate_graphFiles(imports_ontologies_dir, ontologies=ALL_ONTOLOGIES, download=False)
    print(f"    Ontologies processed: {stats}")
    successes.append("Ontologies:all")
except Exception as e:
    print(f"    FAILED ontologies: {str(e)[:200]}")
    traceback.print_exc()
    failures.append("Ontologies:all")

# Step 2: Build databases
print("\n" + "=" * 50)
print("STEP 2: Building Databases")
print("=" * 50)

# Get list of actually available databases
available_dbs = [d for d in os.listdir(databases_dir) if os.path.isdir(os.path.join(databases_dir, d))]
print(f"Found {len(available_dbs)} database directories: {available_dbs}")

# Process all databases at once
try:
    print(f"\n>>> Processing all databases...")
    stats = dh.generateGraphFiles(imports_dir, databases=None, download=False, n_jobs=1)
    print(f"    Databases processed: {stats}")
    successes.append("Databases:all")
except Exception as e:
    print(f"    FAILED databases: {str(e)[:200]}")
    traceback.print_exc()
    failures.append("Databases:all")

# Step 3: Load into Neo4j
print("\n" + "=" * 50)
print("STEP 3: Loading into Neo4j")
print("=" * 50)

try:
    print("Loading ontologies into Neo4j...")
    loader.load_ontologies_into_db()
    print("    SUCCESS: Ontologies loaded")

    print("Loading databases into Neo4j...")
    loader.load_databases_into_db()
    print("    SUCCESS: Databases loaded")

    print("Loading users...")
    loader.load_users_into_db()
    print("    SUCCESS: Users loaded")

except Exception as e:
    print(f"    FAILED loading into Neo4j: {e}")
    traceback.print_exc()
    failures.append("Neo4j:loader")

# Summary
print("\n" + "=" * 50)
print("BUILD SUMMARY")
print("=" * 50)
print(f"Successes: {len(successes)}")
for s in successes:
    print(f"  ✓ {s}")
print(f"\nSkipped: {len(skipped)}")
for s in skipped:
    print(f"  - {s}")
print(f"\nFailures: {len(failures)}")
for f in failures:
    print(f"  ✗ {f}")
print("\nFinished:", datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
PYEOF

echo ""
echo "======================================"
echo "Build finished: $(date)"
echo "======================================"
