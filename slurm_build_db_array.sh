#!/bin/bash -l
#SBATCH --job-name=ckg_db
#SBATCH --array=0-26
#SBATCH --output=/fs/gpfs41/lv12/fileset02/pool/pool-mann-projects/Peter/CKG/logs/ckg_db_%A_%a.out
#SBATCH --error=/fs/gpfs41/lv12/fileset02/pool/pool-mann-projects/Peter/CKG/logs/ckg_db_%A_%a.err
#SBATCH --time=24:00:00
#SBATCH --mem=64G
#SBATCH --partition=p.hpcl93
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4

# Database array - one per task
DATABASES=(
    "HGNC"
    "RefSeq"
    "CORUM"
    "SIGNOR"
    "DGIdb"
    "OncoKB"
    "CancerGenomeInterpreter"
    "SIDER"
    "PhosphoSitePlus"
    "GWASCatalog"
    "MutationDs"
    "Pfam"
    "FooDB"
    "Exposome Explorer"
    "SMPDB"
    "DrugBank"
    "HMDB"
    "Reactome"
    "PathwayCommons"
    "HPA"
    "IntAct"
    "DisGEnet"
    "Jensenlab"
    "Mentions"
    "UniProt"
    "STRING"
    "STITCH"
)

DB_NAME="${DATABASES[$SLURM_ARRAY_TASK_ID]}"

echo "======================================"
echo "CKG Database Download: ${DB_NAME}"
echo "======================================"
echo "Job ID: ${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}"
echo "Array Task: ${SLURM_ARRAY_TASK_ID}"
echo "Database: ${DB_NAME}"
echo "Node: ${HOSTNAME}"
echo "Started: $(date)"
echo "======================================"

# Setup
CKG_DIR="/fs/gpfs41/lv12/fileset02/pool/pool-mann-projects/Peter/CKG"
cd ${CKG_DIR}

source ${CKG_DIR}/venv/bin/activate
export PYTHONPATH=${CKG_DIR}

# Run single database
python3 -u - << EOF
import sys
import traceback
sys.path.insert(0, '${CKG_DIR}')

from ckg import ckg_utils
from ckg.graphdb_builder import builder_utils
from ckg.graphdb_builder.databases import databases_controller as dh

db_name = "${DB_NAME}"
print(f"Processing database: {db_name}", flush=True)

try:
    ckg_config = ckg_utils.read_ckg_config()
    databases_dir = ckg_config['imports_databases_directory']
    builder_utils.checkDirectory(databases_dir)

    stats = dh.generateGraphFiles(databases_dir, [db_name], download=True, n_jobs=1)
    print(f"SUCCESS: {db_name}", flush=True)
except Exception as e:
    print(f"FAILED: {db_name} - {str(e)}", flush=True)
    traceback.print_exc()
    sys.exit(1)
EOF

EXIT_CODE=$?

echo ""
echo "======================================"
echo "Finished: $(date)"
echo "Exit code: ${EXIT_CODE}"
echo "======================================"
