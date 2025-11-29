# alphaCKG - Modernized Clinical Knowledge Graph

**alphaCKG** is a modernized fork of the [Clinical Knowledge Graph (CKG)](https://github.com/MannLabs/CKG), updated for Python 3.10+ and Neo4j 5.x.

## What's Different from Original CKG?

| Feature | Original CKG | alphaCKG |
|---------|-------------|----------|
| Python | 3.7.9 only | 3.10 - 3.12 |
| Neo4j | 4.x | 5.x |
| Pandas | 0.24.x | 2.x |
| Dash | 1.2.x | 2.14+ |
| Docker | Required | Optional |
| Setup | Complex | Single script |

### Code Changes Summary

1. **Pandas modernization**: `.append()` replaced with `pd.concat()`
2. **Dash imports**: Updated to `from dash import html, dcc, dash_table`
3. **Neo4j 5.x**: Updated Cypher syntax (`REQUIRE` vs `ASSERT`, no `USING PERIODIC COMMIT`)
4. **Optional dependencies**: Graceful fallbacks for `xhtml2pdf`, `cyjupyter`, `rpy2`
5. **Database URLs**: Updated to current versions (STRING v12, RefSeq GRCh38.p14, etc.)

---

## Quick Start (5 minutes)

### 1. Clone and Setup

```bash
git clone https://github.com/YOUR_USERNAME/alphaCKG.git
cd alphaCKG

# Run setup (creates venv, installs dependencies)
./setup_ckg.sh
```

### 2. Test Installation

```bash
source venv/bin/activate
PYTHONPATH=. python3 demo_analytics.py
```

Expected output:
```
CKG 2026 - Analytics Demo
==================================================
1. Testing core imports...
   analytics module: OK
2. Generating sample proteomics data...
   Created dataset: 30 samples x 100 proteins
3. Running statistical analysis...
   Top 5 upregulated proteins:
   ...
```

### 3. Run Full Test Suite

```bash
PYTHONPATH=. python3 test_ckg.py
```

---

## Full Setup (with Neo4j Database)

### Prerequisites

- Python 3.10+
- 16GB RAM minimum (32GB recommended)
- 100GB disk space for full database

### Step 1: Setup Python Environment

```bash
./setup_ckg.sh
source venv/bin/activate
```

### Step 2: Install Neo4j 5.x

```bash
# Download Neo4j Community Edition
wget https://neo4j.com/artifact.php?name=neo4j-community-5.26.0-unix.tar.gz -O neo4j.tar.gz
tar xzf neo4j.tar.gz
mv neo4j-community-5.26.0 neo4j/

# Configure Neo4j
cat >> neo4j/conf/neo4j.conf << 'EOF'
# Allow file access from anywhere
#server.directories.import=import

# Memory settings
server.memory.heap.initial_size=4g
server.memory.heap.max_size=8g
server.memory.pagecache.size=4g

# Network
server.default_listen_address=0.0.0.0
EOF

# Set password
neo4j/bin/neo4j-admin dbms set-initial-password your_password

# Start Neo4j
neo4j/bin/neo4j start
```

### Step 3: Configure CKG Connection

Edit `ckg/graphdb_connector/connector_config.yml`:

```yaml
db_url: localhost
db_port: 7687
db_user: neo4j
db_password: your_password
```

### Step 4: Build Database (Optional)

You can either:

**A) Download pre-built database dump** (recommended):
```bash
# Coming soon - database dumps
```

**B) Build from source** (takes several hours):
```bash
# Download raw data
./slurm_download_databases.sh  # or run interactively

# Build import files
python3 build_database_graceful.py

# Load into Neo4j
# See slurm_load_neo4j.sh for commands
```

### Step 5: Start the Web Application

```bash
./start_all.sh start

# Or manually:
source venv/bin/activate
export PYTHONPATH=$PWD
python3 -m ckg.report_manager.index
```

Access at: http://localhost:5000

---

## Project Structure

```
alphaCKG/
├── ckg/                          # Main CKG package
│   ├── analytics_core/           # Statistics, ML, visualization
│   │   ├── analytics/            # Statistical analysis
│   │   └── viz/                  # Visualization functions
│   ├── graphdb_builder/          # Database construction
│   │   ├── builder/              # Core builder + cypher.yml
│   │   ├── databases/            # Database parsers
│   │   ├── experiments/          # Experiment data handlers
│   │   └── ontologies/           # Ontology parsers
│   ├── graphdb_connector/        # Neo4j connection
│   └── report_manager/           # Dash web application
│       └── apps/                 # Application modules
│
├── data/                         # Data directory (gitignored)
│   ├── databases/                # Downloaded raw data
│   ├── imports/                  # Parsed TSV files
│   └── ontologies/               # Ontology files
│
├── neo4j/                        # Neo4j installation (gitignored)
│
├── setup_ckg.sh                  # Quick setup script
├── demo_analytics.py             # Demo without Neo4j
├── test_ckg.py                   # Test suite
├── requirements_modern.txt       # Python dependencies
├── environment.yml               # Conda environment
├── start_all.sh                  # Start all services
│
└── slurm_*.sh                    # HPC job scripts
```

---

## What Works Without Neo4j

The analytics module works standalone:

```python
from ckg.analytics_core.analytics import analytics
import pandas as pd

# Load your proteomics data
data = pd.read_csv("your_data.csv")

# Run analysis
results = analytics.run_anova(data, ...)
pca_result = analytics.run_pca(data, ...)
```

---

## Changes from Original CKG

### Modified Files (32 files)

| Category | Files Changed | Key Changes |
|----------|--------------|-------------|
| Analytics | 3 | pandas `.append()` → `pd.concat()` |
| Dash imports | 12 | `from dash import html, dcc` |
| Neo4j | 2 | `execute_read()`, new Cypher syntax |
| Database configs | 2 | Updated URLs for STRING, RefSeq |
| Optional deps | 3 | Graceful fallbacks for cairo libs |
| Parsers | 5 | Fixed data format changes |
| Setup | 1 | Python 3.10+ |

### New Files

| File | Purpose |
|------|---------|
| `setup_ckg.sh` | One-command installation |
| `demo_analytics.py` | Demo without Neo4j |
| `test_ckg.py` | Comprehensive test suite |
| `requirements_modern.txt` | Updated dependencies |
| `environment.yml` | Conda environment |
| `start_all.sh` | Service manager |
| `build_database_graceful.py` | Robust database builder |
| `slurm_*.sh` | HPC job scripts |

---

## Known Limitations

### Databases Requiring Registration

These databases require manual download:

- **DrugBank** - Requires academic license (drugbank.com)
- **FooDB** - Food database for metabolite-food relationships

Without DrugBank, these parsers are skipped:
- DGIdb drug mappings
- SIDER side effects
- CGI/OncoKB drug targets

### Optional Features

| Feature | Requires | Install |
|---------|----------|---------|
| PDF export | cairo libraries | `pip install xhtml2pdf` |
| Cytoscape Jupyter | pycairo | `pip install cyjupyter` |
| WGCNA (R functions) | R + rpy2 | `pip install rpy2` |

---

## Troubleshooting

### Import Errors

```bash
# Missing package
pip install <package_name>

# Reset environment
rm -rf venv && ./setup_ckg.sh
```

### Neo4j Connection Issues

```bash
# Check Neo4j is running
neo4j/bin/neo4j status

# Test connection
python3 -c "from neo4j import GraphDatabase; d=GraphDatabase.driver('bolt://localhost:7687', auth=('neo4j','your_password')); d.verify_connectivity(); print('OK')"
```

### "PERIODIC COMMIT is no longer supported"

Run the cypher update script:
```bash
python3 update_cypher_to_neo4j5.py
```

---

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes
4. Run tests: `PYTHONPATH=. python3 test_ckg.py`
5. Submit PR

---

## Credits

- Original CKG: [MannLabs/CKG](https://github.com/MannLabs/CKG)
- Paper: [Santos et al., Nature Biotechnology 2022](https://www.nature.com/articles/s41587-021-01145-6)

---

## License

MIT License (same as original CKG)

---

*alphaCKG - November 2025*
