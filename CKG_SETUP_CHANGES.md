# CKG Setup Changes - November 2025

This document outlines all the changes made to get CKG (Clinical Knowledge Graph) running on Neo4j 5.x with updated database sources.

## Overview

CKG was originally designed for Neo4j 4.x. Several updates were required:
1. Cypher query syntax updates for Neo4j 5.x
2. Database URL updates to current versions
3. Parser fixes for changed data formats
4. Neo4j configuration for file access and browser

## 1. Neo4j 5.x Cypher Query Updates

**File**: `ckg/graphdb_builder/builder/cypher.yml`

**Backup**: `ckg/graphdb_builder/builder/cypher_v4.yml.bak`

### Changes Made

The update script `update_cypher_to_neo4j5.py` made these changes:

#### a) CREATE CONSTRAINT syntax
```cypher
-- OLD (Neo4j 4.x):
CREATE CONSTRAINT ON (e:Entity) ASSERT e.id IS UNIQUE;

-- NEW (Neo4j 5.x):
CREATE CONSTRAINT IF NOT EXISTS FOR (e:Entity) REQUIRE e.id IS UNIQUE;
```

#### b) CREATE INDEX syntax
```cypher
-- OLD (Neo4j 4.x):
CREATE INDEX ON :Label(property);

-- NEW (Neo4j 5.x):
CREATE INDEX IF NOT EXISTS FOR (n:Label) ON (n.property);
```

#### c) USING PERIODIC COMMIT
```cypher
-- OLD (Neo4j 4.x):
USING PERIODIC COMMIT 10000
LOAD CSV WITH HEADERS FROM "file:///path" AS line
...

-- NEW (Neo4j 5.x):
LOAD CSV WITH HEADERS FROM "file:///path" AS line
...
-- (Neo4j 5.x handles batching automatically for LOAD CSV)
```

## 2. Database URL Updates

### STRING Database (v12.0)
**File**: `ckg/graphdb_builder/databases/config/stringConfig.yml`

```yaml
# Updated URLs to STRING v12.0
string_url: 'https://stringdb-downloads.org/download/protein.physical.links.full.v12.0/9606.protein.physical.links.full.v12.0.txt.gz'
string_actions_url: 'https://stringdb-downloads.org/download/protein.actions.v11.0/9606.protein.actions.v11.0.txt.gz'
# Note: Actions file only exists in v11.0
string_aliases_url: 'https://stringdb-downloads.org/download/protein.aliases.v12.0/9606.protein.aliases.v12.0.txt.gz'
```

### STRING Mapping Fix
**File**: `ckg/graphdb_builder/mapping.py` (line 164)

```python
# OLD:
def getSTRINGMapping(source="BLAST_UniProt_AC", download=True, db="STRING"):

# NEW (STRING v12.0 changed the alias source name):
def getSTRINGMapping(source="UniProt_AC", download=True, db="STRING"):
```

### RefSeq (GRCh38.p14)
**File**: `ckg/graphdb_builder/databases/config/refseqConfig.yml`

```yaml
# Updated to latest genome assembly
refseq_url: 'https://ftp.ncbi.nlm.nih.gov/genomes/refseq/vertebrate_mammalian/Homo_sapiens/latest_assembly_versions/GCF_000001405.40_GRCh38.p14/GCF_000001405.40_GRCh38.p14_feature_table.txt.gz'
```

### HGNC
**File**: `ckg/graphdb_builder/databases/config/hgncConfig.yml`

```yaml
# Updated to Google Cloud Storage (old FTP deprecated)
hgnc_url: 'https://storage.googleapis.com/public-download-files/hgnc/tsv/tsv/hgnc_complete_set.txt'
```

### Reactome
Download URLs (work without changes):
- https://reactome.org/download/current/ReactomePathways.txt
- https://reactome.org/download/current/ReactomePathwaysRelation.txt
- https://reactome.org/download/current/UniProt2Reactome_PE_Pathway.txt
- https://reactome.org/download/current/ChEBI2Reactome_PE_Pathway.txt

## 3. Neo4j Configuration

**File**: `neo4j/neo4j-community-5.26.0/conf/neo4j.conf`

### Allow file access from anywhere
```properties
# Commented out to allow LOAD CSV from any path
#server.directories.import=import
```

### Memory settings for large datasets (~30GB imports)
```properties
server.memory.heap.initial_size=8g
server.memory.heap.max_size=16g
server.memory.pagecache.size=8g
```

### Enable browser access from outside
```properties
server.default_listen_address=0.0.0.0
```

## 4. Data Built Successfully

| Database | Records | File Size |
|----------|---------|-----------|
| STRING interactions | 53.5M | 14 GB |
| Known variants | 46M | 7.1 GB |
| Proteins | 952K | 76 MB |
| Peptides | 2.5M | 115 MB |
| HMDB metabolites | 218K | 434 MB |
| IntAct interactions | 633K | 93 MB |
| Publications | - | 453 MB |
| Reactome pathways | 2,825 | 6 MB |
| Reactome pathway-protein | 57,568 | |
| Reactome pathway-metabolite | 6,332 | |
| SIGNOR | 5,661 | 370 KB |
| JensenLab | multiple | |
| Genes (HGNC) | 44K | 5.2 MB |

**Total import data**: ~30 GB

## 5. Databases Requiring Registration/License

These databases were skipped because they require registration:

- **DrugBank**: Requires academic license from drugbank.com
- **FooDB**: Food database for metabolite-food relationships

### Parsers Skipped (need Drug mapping from DrugBank):
- DGIdb (Drug-Gene Interaction Database)
- SIDER (Side Effect Database)
- CGI (Cancer Genome Interpreter) - drug targets
- OncoKB - drug targets

### Parser Skipped (needs Food mapping from FooDB):
- Exposome (Food-metabolite exposures)

## 6. Quick Reference Commands

### Start Neo4j
```bash
/fs/pool/pool-mann-projects/Peter/CKG/neo4j/neo4j-community-5.26.0/bin/neo4j start
```

### Access Neo4j Browser
```
http://<server>:7474
Username: neo4j
Password: ckg_password
```

### Run Database Parser
```bash
cd /fs/pool/pool-mann-projects/Peter/CKG
source venv/bin/activate
sbatch slurm_build_<database>.sh
```

### Load Data into Neo4j
```bash
sbatch slurm_load_neo4j.sh
```

## 7. File Structure

```
/fs/pool/pool-mann-projects/Peter/CKG/
├── ckg/                          # Main CKG code
│   ├── graphdb_builder/
│   │   ├── builder/
│   │   │   ├── cypher.yml        # Cypher queries (updated for Neo4j 5.x)
│   │   │   ├── cypher_v4.yml.bak # Backup of original
│   │   │   └── loader.py         # Data loader
│   │   ├── databases/
│   │   │   ├── config/           # Database configs
│   │   │   └── parsers/          # Database parsers
│   │   └── mapping.py            # ID mapping (STRING fix here)
│   └── graphdb_connector/
│       └── connector_config.yml  # Neo4j connection settings
├── data/
│   ├── databases/                # Raw downloaded data
│   └── imports/
│       └── databases/            # Parsed TSV files for Neo4j import
├── neo4j/
│   └── neo4j-community-5.26.0/
│       └── conf/neo4j.conf       # Neo4j configuration
├── slurm_*.sh                    # SLURM job scripts
└── logs/                         # Job output logs
```

## 8. Troubleshooting

### "PERIODIC COMMIT is no longer supported"
Run `update_cypher_to_neo4j5.py` to fix cypher.yml

### STRING produces empty output
Check that `mapping.py` uses `source="UniProt_AC"` not `source="BLAST_UniProt_AC"`

### "File does not exist" during LOAD CSV
Ensure `server.directories.import` is commented out in neo4j.conf

### Database connection fails
Check Neo4j is running: `ps aux | grep neo4j`
Check credentials in `connector_config.yml`

---
*Last updated: November 27, 2025*
