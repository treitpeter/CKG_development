#!/usr/bin/env python3 -u
"""
CKG_PeTr - Graceful Database Builder
Downloads and processes all databases with individual error handling.
If one database fails, continues with the rest.
"""

import os
import sys
import traceback
from datetime import datetime

# Force unbuffered output
sys.stdout.reconfigure(line_buffering=True)
sys.stderr.reconfigure(line_buffering=True)

# Setup path
sys.path.insert(0, '/fs/gpfs41/lv12/fileset02/pool/pool-mann-projects/Peter/CKG')
os.chdir('/fs/gpfs41/lv12/fileset02/pool/pool-mann-projects/Peter/CKG')

from ckg import ckg_utils
from ckg.graphdb_builder import builder_utils
from ckg.graphdb_builder.ontologies import ontologies_controller as oh
from ckg.graphdb_builder.databases import databases_controller as dh
from ckg.graphdb_builder.builder import loader

# Load configurations
ckg_config = ckg_utils.read_ckg_config()
log_config = ckg_config['graphdb_builder_log']
logger = builder_utils.setup_logging(log_config, key="graceful_builder")
dbconfig = builder_utils.setup_config('databases')
oconfig = builder_utils.setup_config('ontologies')

# Databases to process (ordered by typical size: small -> large)
ALL_DATABASES = [
    "HGNC",           # Small: gene nomenclature
    "RefSeq",         # Small: reference sequences
    "CORUM",          # Small: protein complexes
    "SIGNOR",         # Small: signaling network
    "DGIdb",          # Small: drug-gene interactions
    "OncoKB",         # Small: cancer variants
    "CancerGenomeInterpreter",  # Small
    "SIDER",          # Medium: drug side effects
    "PhosphoSitePlus", # Medium: phosphorylation sites
    "GWASCatalog",    # Medium: GWAS associations
    "MutationDs",     # Medium: mutations
    "Pfam",           # Medium: protein families
    "FooDB",          # Medium: food compounds
    "Exposome Explorer", # Medium
    "SMPDB",          # Medium: metabolic pathways
    "DrugBank",       # Medium-Large: drug database
    "HMDB",           # Large: metabolome database (~5GB)
    "Reactome",       # Large: pathway database
    "PathwayCommons", # Large: pathway database
    "HPA",            # Large: human protein atlas
    "IntAct",         # Large: protein interactions
    "DisGEnet",       # Large: disease-gene associations
    "Jensenlab",      # Large: text mining
    "Mentions",       # Very Large: PubMed mentions (~20GB)
    "UniProt",        # Very Large: protein database (~15GB)
    "STRING",         # Very Large: protein network (~10GB)
    "STITCH",         # Very Large: chemical-protein (~15GB)
]

# Ontologies to process
ALL_ONTOLOGIES = [
    "Amino_acid",
    "Clinical_variable",
    "Disease",
    "Drug",
    "Experimental_factor",
    "Food",
    "Gene_ontology",
    "Modification",
    "Pathway",
    "Phenotype",
    "Publication",
    "Tissue",
    "Units",
]

def log_status(message, level="INFO"):
    """Log to both console and file"""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    formatted = f"[{timestamp}] [{level}] {message}"
    print(formatted, flush=True)
    if level == "ERROR":
        logger.error(message)
    else:
        logger.info(message)

def process_ontologies(download=True):
    """Process all ontologies with individual error handling"""
    log_status("=" * 60)
    log_status("PROCESSING ONTOLOGIES")
    log_status("=" * 60)

    ontologies_dir = ckg_config['imports_ontologies_directory']
    builder_utils.checkDirectory(ontologies_dir)

    success_count = 0
    fail_count = 0

    for ontology in ALL_ONTOLOGIES:
        try:
            log_status(f"Processing ontology: {ontology}")
            stats = oh.generate_graphFiles(ontologies_dir, [ontology], download)
            log_status(f"  -> Success: {ontology}")
            success_count += 1
        except Exception as e:
            log_status(f"  -> FAILED: {ontology} - {str(e)[:100]}", "ERROR")
            traceback.print_exc()
            fail_count += 1
            continue

    log_status(f"Ontologies complete: {success_count} success, {fail_count} failed")
    return success_count, fail_count

def process_databases(databases=None, download=True, n_jobs=2):
    """Process all databases with individual error handling"""
    log_status("=" * 60)
    log_status("PROCESSING DATABASES")
    log_status("=" * 60)

    if databases is None:
        databases = ALL_DATABASES

    databases_dir = ckg_config['imports_databases_directory']
    builder_utils.checkDirectory(databases_dir)

    success_count = 0
    fail_count = 0
    skipped = []

    for db in databases:
        try:
            log_status(f"Processing database: {db}")
            stats = dh.generateGraphFiles(databases_dir, [db], download, n_jobs=1)
            log_status(f"  -> Success: {db}")
            success_count += 1
        except Exception as e:
            error_msg = str(e)[:200]
            log_status(f"  -> FAILED: {db} - {error_msg}", "ERROR")
            traceback.print_exc()
            fail_count += 1
            skipped.append(db)
            continue

    log_status(f"Databases complete: {success_count} success, {fail_count} failed")
    if skipped:
        log_status(f"Skipped databases: {', '.join(skipped)}")
    return success_count, fail_count, skipped

def load_to_neo4j():
    """Load all processed data into Neo4j"""
    log_status("=" * 60)
    log_status("LOADING DATA INTO NEO4J")
    log_status("=" * 60)

    try:
        loader.fullUpdate()
        log_status("Neo4j load complete!")
        return True
    except Exception as e:
        log_status(f"Neo4j load FAILED: {str(e)}", "ERROR")
        traceback.print_exc()
        return False

def main():
    log_status("=" * 60)
    log_status("CKG_PeTr GRACEFUL DATABASE BUILD")
    log_status("=" * 60)
    log_status("")
    log_status("This will download ~80GB of biomedical data from:")
    log_status(f"  - {len(ALL_ONTOLOGIES)} ontologies")
    log_status(f"  - {len(ALL_DATABASES)} databases")
    log_status("")
    log_status("Failed downloads will be skipped gracefully.")
    log_status("")

    start_time = datetime.now()

    # Step 1: Ontologies
    ont_success, ont_fail = process_ontologies(download=True)

    # Step 2: Databases
    db_success, db_fail, skipped = process_databases(download=True)

    # Step 3: Load to Neo4j
    neo4j_success = load_to_neo4j()

    # Summary
    end_time = datetime.now()
    duration = end_time - start_time

    log_status("")
    log_status("=" * 60)
    log_status("BUILD COMPLETE")
    log_status("=" * 60)
    log_status(f"Duration: {duration}")
    log_status(f"Ontologies: {ont_success} success, {ont_fail} failed")
    log_status(f"Databases: {db_success} success, {db_fail} failed")
    log_status(f"Neo4j load: {'SUCCESS' if neo4j_success else 'FAILED'}")
    if skipped:
        log_status(f"Skipped: {', '.join(skipped)}")
    log_status("")

    # Write summary to file
    with open('/tmp/ckg_build_summary.txt', 'w') as f:
        f.write(f"CKG Build Summary\n")
        f.write(f"Start: {start_time}\n")
        f.write(f"End: {end_time}\n")
        f.write(f"Duration: {duration}\n")
        f.write(f"Ontologies: {ont_success}/{len(ALL_ONTOLOGIES)}\n")
        f.write(f"Databases: {db_success}/{len(ALL_DATABASES)}\n")
        f.write(f"Neo4j: {'OK' if neo4j_success else 'FAILED'}\n")
        if skipped:
            f.write(f"Skipped: {', '.join(skipped)}\n")

if __name__ == "__main__":
    main()
