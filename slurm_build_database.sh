#!/bin/bash -l
#SBATCH --job-name=ckg_db_build
#SBATCH --output=/fs/gpfs41/lv12/fileset02/pool/pool-mann-projects/Peter/CKG/logs/ckg_build_%j.out
#SBATCH --error=/fs/gpfs41/lv12/fileset02/pool/pool-mann-projects/Peter/CKG/logs/ckg_build_%j.err
#SBATCH --time=48:00:00
#SBATCH --mem=128G
#SBATCH --partition=p.hpcl93
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8

echo "======================================"
echo "CKG Database Build - Full 80GB"
echo "======================================"
echo "Job ID: ${SLURM_JOB_ID}"
echo "Node: ${HOSTNAME}"
echo "Started: $(date)"
echo "======================================"

# Setup
CKG_DIR="/fs/gpfs41/lv12/fileset02/pool/pool-mann-projects/Peter/CKG"
cd ${CKG_DIR}

# Activate virtual environment
source ${CKG_DIR}/venv/bin/activate
export PYTHONPATH=${CKG_DIR}

# Create logs directory if it doesn't exist
mkdir -p ${CKG_DIR}/logs

echo ""
echo "Python: $(which python3)"
echo "Working dir: $(pwd)"
echo ""

# Run the graceful build script
python3 -u ${CKG_DIR}/build_database_graceful.py

echo ""
echo "======================================"
echo "Build finished: $(date)"
echo "======================================"
