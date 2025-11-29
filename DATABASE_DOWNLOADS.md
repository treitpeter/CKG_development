# CKG Database Download Guide

This document describes how to download external databases used by CKG, including known issues and workarounds as of November 2025.

## Quick Start

**To download all databases at once, submit the SLURM job:**
```bash
sbatch slurm_download_databases.sh
```

This will download DGIdb, CGI, HPA, Exposome Explorer, and Pfam automatically.

## Status Overview (November 2025)

| Database | Status | Size | Notes |
|----------|--------|------|-------|
| DGIdb | ✅ Fixed | 7.8MB | Use GraphQL API (old TSV URLs broken) |
| CGI | ✅ Fixed | 264KB | Use new TSV endpoint |
| HPA | ✅ Fixed | 38MB | Use `proteinatlas.tsv.zip` |
| Exposome Explorer | ✅ Working | 3.4MB | Original URLs work |
| Pfam | ✅ Fixed | 23GB | Use HTTPS instead of FTP |
| OncoKB | ⚠️ Auth Required | - | Register for free API token |

---

## Database-Specific Instructions

### 1. DGIdb (Drug Gene Interaction Database)

**Problem:** Old TSV download URLs redirect to a JavaScript app that doesn't serve data directly.

**Solution:** Use GraphQL API to fetch all interactions programmatically.

**The SLURM script handles this automatically**, but for manual download:

```python
import requests
import csv

url = "https://dgidb.org/api/graphql"
query = """
query($after: String) {
  interactions(first: 1000, after: $after) {
    pageInfo { hasNextPage endCursor }
    nodes {
      drug { name conceptId }
      gene { name conceptId }
      interactionScore
      interactionTypes { type }
      publications { pmid }
      sources { fullName }
    }
  }
}
"""

# Paginate through all results
all_interactions = []
after = None
while True:
    resp = requests.post(url, json={"query": query, "variables": {"after": after}})
    data = resp.json()["data"]["interactions"]
    all_interactions.extend(data["nodes"])
    if not data["pageInfo"]["hasNextPage"]:
        break
    after = data["pageInfo"]["endCursor"]

# Write to TSV (see slurm_download_databases.sh for full implementation)
```

**Expected result:** ~70,000 drug-gene interactions

**Source:** https://dgidb.org/

---

### 2. OncoKB

**Issue:** OncoKB now requires authentication via API token.

**Steps to get access:**
1. Register at https://www.oncokb.org/account/register
2. Wait for account approval
3. Get your API token from Account Settings
4. Token expires after 6 months (auto-renews after verification)

**API Documentation:** https://api.oncokb.org/

**Free Downloads (no auth required):**
- Cancer Gene List: https://www.oncokb.org/cancerGenes
- All Curated Genes: Available on website
- Biomarker-Drug Associations: Available on website

**For bulk variant data:** Must use API with token in request header.

**Note:** OncoKB discourages bulk downloads of annotated variants as they update frequently. They recommend using the API for real-time annotation.

---

### 3. Cancer Genome Interpreter (CGI)

**Problem:** Old zip download URLs return 404.

**Working URL:**
```
https://www.cancergenomeinterpreter.org/data/biomarkers/cgi_biomarkers_latest.tsv
```

**Manual Download:**
```bash
curl -o cgi_biomarkers.tsv "https://www.cancergenomeinterpreter.org/data/biomarkers/cgi_biomarkers_latest.tsv"
```

**Expected result:** ~1,170 biomarker entries

**Source:** https://www.cancergenomeinterpreter.org/biomarkers

---

### 4. Pfam

**Problem:** FTP access blocked on many networks; old filename `Pfam-A.full.uniprot.gz` doesn't exist.

**Solution:** Use HTTPS mirror instead of FTP.

**Working URLs:**
```bash
# Full alignments (23GB - required for CKG)
wget -c "https://ftp.ebi.ac.uk/pub/databases/Pfam/current_release/Pfam-A.full.gz"

# HMM data
wget -c "https://ftp.ebi.ac.uk/pub/databases/Pfam/current_release/Pfam-A.hmm.dat.gz"

# Clan info
wget -c "https://ftp.ebi.ac.uk/pub/databases/Pfam/current_release/Pfam-A.clans.tsv.gz"
```

**Note:** Use `wget -c` for resume capability on large files.

**Source:** https://www.ebi.ac.uk/interpro/download/pfam/

---

### 5. Exposome Explorer

**Status:** Working as-is.

**URLs:**
```bash
curl -o biomarkers.csv.zip "http://exposome-explorer.iarc.fr/system/downloads/current/biomarkers.csv.zip"
curl -o correlations.csv.zip "http://exposome-explorer.iarc.fr/system/downloads/current/correlations.csv.zip"
```

**Source:** http://exposome-explorer.iarc.fr/releases

---

### 6. Human Protein Atlas (HPA)

**Problem:** Old URL `pathology.tsv.zip` returns 404.

**Working URL:**
```bash
curl -o proteinatlas.tsv.zip "https://www.proteinatlas.org/download/proteinatlas.tsv.zip"
```

**Expected result:** ~38MB uncompressed

**Source:** https://www.proteinatlas.org/about/download

---

### 7. OncoKB (Optional)

**Status:** Requires free registration for API access.

**Steps:**
1. Register at https://www.oncokb.org/account/register
2. Wait for approval (usually quick)
3. Get API token from Account Settings
4. Download with token:

```bash
export ONCOKB_TOKEN="your_token_here"
curl -H "Authorization: Bearer $ONCOKB_TOKEN" \
    -o allAnnotatedVariants.txt \
    "https://www.oncokb.org/api/v1/utils/allAnnotatedVariants.txt"
```

**Note:** OncoKB is optional for basic CKG demo functionality. It adds cancer variant annotations but is not required for core proteomics analysis.

**Source:** https://www.oncokb.org/

---

## Troubleshooting

### FTP Blocked
Replace `ftp://ftp.ebi.ac.uk` with `https://ftp.ebi.ac.uk`

### Large File Downloads
Use wget with resume capability:
```bash
wget -c "https://url/to/large/file.gz"
```

### Timeout Issues
```bash
curl --max-time 600 -o file.gz "https://..."
```

---

## Verified Downloads (November 26, 2025)

All databases successfully downloaded with these sizes:

| Database | Files | Size |
|----------|-------|------|
| DGIdb | interactions.tsv | 7.8MB (69,907 interactions) |
| CGI | cgi_biomarkers.tsv | 264KB (1,170 entries) |
| HPA | proteinatlas.tsv | 38MB |
| Exposome Explorer | biomarkers.csv, correlations.csv | 3.4MB |
| Pfam | Pfam-A.full.gz + metadata | 23GB |

---

## References
- DGIdb: https://dgidb.org/
- OncoKB: https://www.oncokb.org/
- Cancer Genome Interpreter: https://www.cancergenomeinterpreter.org/
- Pfam/InterPro: https://www.ebi.ac.uk/interpro/
- Exposome Explorer: http://exposome-explorer.iarc.fr/
- Human Protein Atlas: https://www.proteinatlas.org/
