#!/bin/bash -l
#SBATCH --job-name=ckg_download
#SBATCH --output=/fs/gpfs41/lv12/fileset02/pool/pool-mann-projects/Peter/CKG/logs/ckg_download_%j.out
#SBATCH --error=/fs/gpfs41/lv12/fileset02/pool/pool-mann-projects/Peter/CKG/logs/ckg_download_%j.err
#SBATCH --time=12:00:00
#SBATCH --mem=32G
#SBATCH --partition=p.hpcl93
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4

echo "=============================================="
echo "CKG Database Downloads"
echo "Started: $(date)"
echo "Node: ${HOSTNAME}"
echo "=============================================="

CKG_DIR="/fs/gpfs41/lv12/fileset02/pool/pool-mann-projects/Peter/CKG"
DATA_DIR="${CKG_DIR}/data/databases"
cd ${CKG_DIR}

source ${CKG_DIR}/venv/bin/activate
export PYTHONPATH=${CKG_DIR}

# Track successes and failures
SUCCESSES=""
FAILURES=""

#######################################
# 1. DGIdb - via GraphQL API
#######################################
echo ""
echo "=== Downloading DGIdb ==="
mkdir -p "${DATA_DIR}/DGIdb"

python3 << 'PYEOF'
import requests
import csv
import sys

url = "https://dgidb.org/api/graphql"
output_file = "/fs/gpfs41/lv12/fileset02/pool/pool-mann-projects/Peter/CKG/data/databases/DGIdb/interactions.tsv"

query = """
query($after: String) {
  interactions(first: 1000, after: $after) {
    pageInfo { hasNextPage endCursor }
    nodes {
      drug { name conceptId }
      gene { name conceptId }
      interactionScore
      interactionTypes { type directionality }
      publications { pmid }
      sources { fullName }
    }
  }
}
"""

all_interactions = []
after = None
page = 0

try:
    while True:
        page += 1
        if page % 10 == 0:
            print(f"DGIdb: Fetching page {page}...", flush=True)
        resp = requests.post(url, json={"query": query, "variables": {"after": after}}, timeout=60)
        resp.raise_for_status()
        data = resp.json()["data"]["interactions"]
        all_interactions.extend(data["nodes"])
        if not data["pageInfo"]["hasNextPage"]:
            break
        after = data["pageInfo"]["endCursor"]

    print(f"DGIdb: Total interactions: {len(all_interactions)}")

    with open(output_file, "w", newline="") as f:
        writer = csv.writer(f, delimiter="\t")
        writer.writerow(["drug_name", "drug_id", "gene_name", "gene_id", "score", "interaction_types", "pmids", "sources"])
        for i in all_interactions:
            writer.writerow([
                i["drug"]["name"] if i["drug"] else "",
                i["drug"]["conceptId"] if i["drug"] else "",
                i["gene"]["name"] if i["gene"] else "",
                i["gene"]["conceptId"] if i["gene"] else "",
                i.get("interactionScore", ""),
                ";".join([t["type"] for t in (i.get("interactionTypes") or [])]),
                ";".join([str(p["pmid"]) for p in (i.get("publications") or []) if p.get("pmid")]),
                ";".join([s["fullName"] for s in (i.get("sources") or [])])
            ])
    print(f"DGIdb: SUCCESS - Written {len(all_interactions)} interactions")
    sys.exit(0)
except Exception as e:
    print(f"DGIdb: FAILED - {e}")
    sys.exit(1)
PYEOF

if [ $? -eq 0 ]; then SUCCESSES="$SUCCESSES DGIdb"; else FAILURES="$FAILURES DGIdb"; fi

#######################################
# 2. Cancer Genome Interpreter
#######################################
echo ""
echo "=== Downloading Cancer Genome Interpreter ==="
mkdir -p "${DATA_DIR}/CancerGenomeInterpreter"

curl -sL --max-time 300 -o "${DATA_DIR}/CancerGenomeInterpreter/cgi_biomarkers.tsv" \
    "https://www.cancergenomeinterpreter.org/data/biomarkers/cgi_biomarkers_latest.tsv"

if [ -s "${DATA_DIR}/CancerGenomeInterpreter/cgi_biomarkers.tsv" ]; then
    lines=$(wc -l < "${DATA_DIR}/CancerGenomeInterpreter/cgi_biomarkers.tsv")
    echo "CGI: SUCCESS - Downloaded ${lines} lines"
    SUCCESSES="$SUCCESSES CGI"
else
    echo "CGI: FAILED - Empty or missing file"
    FAILURES="$FAILURES CGI"
fi

#######################################
# 3. Human Protein Atlas
#######################################
echo ""
echo "=== Downloading HPA ==="
mkdir -p "${DATA_DIR}/HPA"

curl -sL --max-time 600 -o "${DATA_DIR}/HPA/proteinatlas.tsv.zip" \
    "https://www.proteinatlas.org/download/proteinatlas.tsv.zip"

if [ -s "${DATA_DIR}/HPA/proteinatlas.tsv.zip" ]; then
    size=$(ls -lh "${DATA_DIR}/HPA/proteinatlas.tsv.zip" | awk '{print $5}')
    echo "HPA: SUCCESS - Downloaded ${size}"
    cd "${DATA_DIR}/HPA" && unzip -o proteinatlas.tsv.zip 2>/dev/null && cd ${CKG_DIR}
    SUCCESSES="$SUCCESSES HPA"
else
    echo "HPA: FAILED - Empty or missing file"
    FAILURES="$FAILURES HPA"
fi

#######################################
# 4. Exposome Explorer
#######################################
echo ""
echo "=== Downloading Exposome Explorer ==="
mkdir -p "${DATA_DIR}/ExposomeExplorer"

curl -sL --max-time 300 -o "${DATA_DIR}/ExposomeExplorer/biomarkers.csv.zip" \
    "http://exposome-explorer.iarc.fr/system/downloads/current/biomarkers.csv.zip"
curl -sL --max-time 300 -o "${DATA_DIR}/ExposomeExplorer/correlations.csv.zip" \
    "http://exposome-explorer.iarc.fr/system/downloads/current/correlations.csv.zip"

if [ -s "${DATA_DIR}/ExposomeExplorer/biomarkers.csv.zip" ]; then
    echo "Exposome: SUCCESS"
    cd "${DATA_DIR}/ExposomeExplorer" && unzip -o "*.zip" 2>/dev/null && cd ${CKG_DIR}
    SUCCESSES="$SUCCESSES Exposome"
else
    echo "Exposome: FAILED"
    FAILURES="$FAILURES Exposome"
fi

#######################################
# 5. Pfam - Large files, use wget with resume
#######################################
echo ""
echo "=== Downloading Pfam ==="
mkdir -p "${DATA_DIR}/Pfam"

# Download the HMM data file (smaller, ~200MB)
echo "Downloading Pfam-A.hmm.dat.gz..."
wget -q --timeout=600 -c -O "${DATA_DIR}/Pfam/Pfam-A.hmm.dat.gz" \
    "https://ftp.ebi.ac.uk/pub/databases/Pfam/current_release/Pfam-A.hmm.dat.gz"

# Download clans info
echo "Downloading Pfam-A.clans.tsv.gz..."
wget -q --timeout=300 -c -O "${DATA_DIR}/Pfam/Pfam-A.clans.tsv.gz" \
    "https://ftp.ebi.ac.uk/pub/databases/Pfam/current_release/Pfam-A.clans.tsv.gz"

# Download the full alignments (large ~14GB but needed)
echo "Downloading Pfam-A.full.gz (this may take a while)..."
wget -q --timeout=3600 -c -O "${DATA_DIR}/Pfam/Pfam-A.full.gz" \
    "https://ftp.ebi.ac.uk/pub/databases/Pfam/current_release/Pfam-A.full.gz"

if [ -s "${DATA_DIR}/Pfam/Pfam-A.hmm.dat.gz" ]; then
    size=$(ls -lh "${DATA_DIR}/Pfam/Pfam-A.full.gz" 2>/dev/null | awk '{print $5}')
    echo "Pfam: SUCCESS - Full file: ${size}"
    SUCCESSES="$SUCCESSES Pfam"
else
    echo "Pfam: FAILED"
    FAILURES="$FAILURES Pfam"
fi

#######################################
# 6. OncoKB - Requires API token
#######################################
echo ""
echo "=== OncoKB ==="
echo "OncoKB requires API registration. Please:"
echo "1. Register at https://www.oncokb.org/account/register"
echo "2. Get your API token from Account Settings"
echo "3. Download manually or set ONCOKB_TOKEN environment variable"

# If token is set, try to download
if [ -n "${ONCOKB_TOKEN}" ]; then
    mkdir -p "${DATA_DIR}/OncoKB"
    curl -sL --max-time 300 -H "Authorization: Bearer ${ONCOKB_TOKEN}" \
        -o "${DATA_DIR}/OncoKB/allAnnotatedVariants.txt" \
        "https://www.oncokb.org/api/v1/utils/allAnnotatedVariants.txt"
    if [ -s "${DATA_DIR}/OncoKB/allAnnotatedVariants.txt" ]; then
        echo "OncoKB: SUCCESS"
        SUCCESSES="$SUCCESSES OncoKB"
    else
        echo "OncoKB: FAILED - Check token"
        FAILURES="$FAILURES OncoKB"
    fi
else
    echo "OncoKB: SKIPPED - No token set"
fi

#######################################
# Summary
#######################################
echo ""
echo "=============================================="
echo "DOWNLOAD SUMMARY"
echo "=============================================="
echo "Successes:${SUCCESSES}"
echo "Failures:${FAILURES}"
echo ""
echo "=== Final file sizes ==="
for db in DGIdb CancerGenomeInterpreter HPA ExposomeExplorer Pfam OncoKB; do
    echo "--- $db ---"
    ls -lh "${DATA_DIR}/$db/" 2>/dev/null || echo "  Not found"
done
echo ""
echo "Finished: $(date)"
echo "=============================================="
