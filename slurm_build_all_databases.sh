#!/bin/bash -l
#SBATCH --job-name=ckg_build_all
#SBATCH --output=/fs/pool/pool-mann-projects/Peter/CKG/logs/ckg_build_all_%j.out
#SBATCH --error=/fs/pool/pool-mann-projects/Peter/CKG/logs/ckg_build_all_%j.err
#SBATCH --time=24:00:00
#SBATCH --mem=150G
#SBATCH --cpus-per-task=16
#SBATCH --partition=p.hpcl93
#SBATCH --nodes=1

echo "======================================"
echo "CKG Build ALL Available Databases"
echo "======================================"
echo "Job ID: ${SLURM_JOB_ID}"
echo "Node: $(hostname)"
echo "Started: $(date)"
echo "======================================"

cd /fs/pool/pool-mann-projects/Peter/CKG
source venv/bin/activate

export PYTHONUNBUFFERED=1

python3 -u << 'PYTHON_SCRIPT'
import sys
import os
import time

sys.stdout = os.fdopen(sys.stdout.fileno(), 'w', buffering=1)

print("=" * 70)
print("CKG DATABASE BUILD - VERIFIED WORKING PARSERS")
print("=" * 70)
sys.stdout.flush()

db_dir = '/fs/pool/pool-mann-projects/Peter/CKG/data/databases'
import_dir = '/fs/pool/pool-mann-projects/Peter/CKG/data/imports/databases'

os.makedirs(import_dir, exist_ok=True)

# VERIFIED working parsers - no missing mapping dependencies
# Available mappings: Protein (UniProt), Metabolite (HMDB), Pathway (Reactome)
# Missing: Drug (DrugBank), Food (FooDB), Gene (HGNC), Disease (DO)
parsers_working = [
    ("SIGNOR", "signorParser"),           # Works - no mapping needed
    ("DisGeNET", "disgenetParser"),       # Works - no mapping needed
    ("CORUM", "corumParser"),             # Works - no mapping needed
    ("MutationDs", "mutationDsParser"),   # Works - no mapping needed
    ("RefSeq", "refseqParser"),           # Works - no mapping needed
    ("PathwayCommons", "pathwayCommonsParser"),  # Works - no mapping needed
    ("GWAS Catalog", "gwasCatalogParser"), # Works - no mapping needed
    ("JensenLab", "jensenlabParser"),     # Works - no mapping needed
    ("GOA", "goaParser"),                 # Works - no mapping needed
    ("HPA", "hpaParser"),                 # Needs Protein mapping (available)
    ("IntAct", "intactParser"),           # Large - no mapping needed
    ("HMDB", "hmdbParser"),               # Large - no mapping needed
]

results = {"success": [], "failed": [], "skipped": []}

def save_to_tsv(data, header, name, import_dir):
    if not data:
        return 0
    filepath = os.path.join(import_dir, f"{name}.tsv")
    with open(filepath, 'w') as f:
        if header:
            f.write('\t'.join(str(h) for h in header) + '\n')
        for row in data:
            f.write('\t'.join(str(x) for x in row) + '\n')
    return len(data)

for db_name, parser_name in parsers_working:
    print(f"\n{'=' * 70}")
    print(f"[{time.strftime('%H:%M:%S')}] Building: {db_name}")
    print('=' * 70)
    sys.stdout.flush()

    start_time = time.time()
    try:
        exec(f"from ckg.graphdb_builder.databases.parsers import {parser_name}")
        parser_module = eval(parser_name)

        result = parser_module.parser(db_dir, download=False)
        elapsed = time.time() - start_time

        if result:
            if isinstance(result, tuple) and len(result) >= 2:
                data, header = result[0], result[1]
                if data:
                    count = save_to_tsv(data, header, db_name, import_dir)
                    print(f"  -> Saved {count} rows to {db_name}.tsv")
            print(f"SUCCESS: {db_name} ({elapsed:.1f}s)")
        else:
            print(f"SUCCESS: {db_name} ({elapsed:.1f}s) - no data returned")
        results["success"].append(db_name)
        sys.stdout.flush()

    except FileNotFoundError as e:
        print(f"SKIPPED: {db_name} - {e}")
        results["skipped"].append(db_name)
        sys.stdout.flush()
    except Exception as e:
        elapsed = time.time() - start_time
        print(f"ERROR in {db_name} ({elapsed:.1f}s): {type(e).__name__}: {e}")
        import traceback
        traceback.print_exc()
        results["failed"].append(db_name)
        sys.stdout.flush()

# STRING parser (special signature - writes directly)
print(f"\n{'=' * 70}")
print(f"[{time.strftime('%H:%M:%S')}] Building: STRING")
print('=' * 70)
sys.stdout.flush()
try:
    from ckg.graphdb_builder.databases.parsers import stringParser
    start_time = time.time()
    stringParser.parser(db_dir, import_dir, drug_source=None, download=False, db="STRING")
    elapsed = time.time() - start_time
    print(f"SUCCESS: STRING ({elapsed:.1f}s)")
    results["success"].append("STRING")
except Exception as e:
    print(f"ERROR in STRING: {type(e).__name__}: {e}")
    import traceback
    traceback.print_exc()
    results["failed"].append("STRING")
sys.stdout.flush()

# Pfam parser (special signature)
print(f"\n{'=' * 70}")
print(f"[{time.strftime('%H:%M:%S')}] Building: Pfam")
print('=' * 70)
sys.stdout.flush()
try:
    from ckg.graphdb_builder.databases.parsers import pfamParser
    start_time = time.time()
    pfamParser.parser(db_dir, import_dir, download=False)
    elapsed = time.time() - start_time
    print(f"SUCCESS: Pfam ({elapsed:.1f}s)")
    results["success"].append("Pfam")
except Exception as e:
    print(f"ERROR in Pfam: {type(e).__name__}: {e}")
    import traceback
    traceback.print_exc()
    results["failed"].append("Pfam")
sys.stdout.flush()

# TextMining parser (special signature)
print(f"\n{'=' * 70}")
print(f"[{time.strftime('%H:%M:%S')}] Building: TextMining")
print('=' * 70)
sys.stdout.flush()
try:
    from ckg.graphdb_builder.databases.parsers import textminingParser
    start_time = time.time()
    textminingParser.parser(db_dir, import_dir, download=False)
    elapsed = time.time() - start_time
    print(f"SUCCESS: TextMining ({elapsed:.1f}s)")
    results["success"].append("TextMining")
except Exception as e:
    print(f"ERROR in TextMining: {type(e).__name__}: {e}")
    import traceback
    traceback.print_exc()
    results["failed"].append("TextMining")
sys.stdout.flush()

print("\n" + "=" * 70)
print("BUILD SUMMARY")
print("=" * 70)
print(f"SUCCESS ({len(results['success'])}): {', '.join(results['success'])}")
print(f"FAILED  ({len(results['failed'])}): {', '.join(results['failed'])}")
print(f"SKIPPED ({len(results['skipped'])}): {', '.join(results['skipped'])}")
print("=" * 70)
print("\nSkipped due to missing DrugBank: DGIdb, SIDER, CGI, OncoKB, Reactome")
print("Skipped due to missing FooDB: Exposome")
sys.stdout.flush()
PYTHON_SCRIPT

echo ""
echo "======================================"
echo "Output files:"
echo "======================================"
ls -lh /fs/pool/pool-mann-projects/Peter/CKG/data/imports/databases/*.tsv 2>/dev/null | tail -40
echo ""
echo "Total: $(ls /fs/pool/pool-mann-projects/Peter/CKG/data/imports/databases/*.tsv 2>/dev/null | wc -l) files"
echo "Size: $(du -sh /fs/pool/pool-mann-projects/Peter/CKG/data/imports/databases/ 2>/dev/null | cut -f1)"
echo ""
echo "Finished: $(date)"
