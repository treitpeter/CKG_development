#!/bin/bash -l
#SBATCH --job-name=ckg_ont
#SBATCH --output=/fs/gpfs41/lv12/fileset02/pool/pool-mann-projects/Peter/CKG/logs/ckg_ontologies_%j.out
#SBATCH --error=/fs/gpfs41/lv12/fileset02/pool/pool-mann-projects/Peter/CKG/logs/ckg_ontologies_%j.err
#SBATCH --time=2:00:00
#SBATCH --mem=32G
#SBATCH --partition=p.hpcl93
#SBATCH --nodes=1

echo "======================================"
echo "CKG Ontologies Download"
echo "======================================"
echo "Job ID: ${SLURM_JOB_ID}"
echo "Node: ${HOSTNAME}"
echo "Started: $(date)"
echo "======================================"

CKG_DIR="/fs/gpfs41/lv12/fileset02/pool/pool-mann-projects/Peter/CKG"
cd ${CKG_DIR}

source ${CKG_DIR}/venv/bin/activate
export PYTHONPATH=${CKG_DIR}

python3 -u - << 'EOF'
import sys
sys.path.insert(0, '/fs/gpfs41/lv12/fileset02/pool/pool-mann-projects/Peter/CKG')

from ckg import ckg_utils
from ckg.graphdb_builder import builder_utils
from ckg.graphdb_builder.ontologies import ontologies_controller as oh

ALL_ONTOLOGIES = [
    "Amino_acid", "Clinical_variable", "Disease", "Drug",
    "Experimental_factor", "Food", "Gene_ontology", "Modification",
    "Pathway", "Phenotype", "Publication", "Tissue", "Units"
]

ckg_config = ckg_utils.read_ckg_config()
ontologies_dir = ckg_config['imports_ontologies_directory']
builder_utils.checkDirectory(ontologies_dir)

for ont in ALL_ONTOLOGIES:
    try:
        print(f"Processing: {ont}", flush=True)
        oh.generate_graphFiles(ontologies_dir, [ont], download=True)
        print(f"  -> SUCCESS: {ont}", flush=True)
    except Exception as e:
        print(f"  -> FAILED: {ont} - {e}", flush=True)

print("Ontologies complete!", flush=True)
EOF

echo "======================================"
echo "Finished: $(date)"
echo "======================================"
