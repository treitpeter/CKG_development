# CKG 2026 - Quick Start Guide

This is the modernized version of the Clinical Knowledge Graph (CKG), updated for Python 3.10+.

## Quick Install

```bash
# Clone or enter the CKG directory
cd CKG

# Run setup script
./setup_ckg.sh

# Or manually:
python3 -m venv venv
source venv/bin/activate
pip install -r requirements_modern.txt
```

## Test the Installation

```bash
source venv/bin/activate
PYTHONPATH=. python3 demo_analytics.py
```

You should see output demonstrating:
- Statistical analysis
- PCA/UMAP dimensionality reduction
- Network analysis
- Community detection

## What's Different in CKG 2026

### Updated Dependencies
- Python 3.10+ (was 3.7.9)
- pandas 2.x (was 0.24)
- dash 2.x (was 1.2)
- neo4j 5.x/6.x (was 4.2)
- scipy 1.11+ (was 1.4)
- networkx 3.x (was 2.5)

### Code Fixes
- Updated dash imports (`from dash import html, dcc`)
- Fixed deprecated pandas `.append()` → `pd.concat()`
- Updated neo4j driver API (`execute_read` vs `read_transaction`)
- Made optional deps truly optional (xhtml2pdf, cyjupyter, rpy2)

## Optional Components

### R Integration (for WGCNA)
If you need R functions, install R and rpy2:
```bash
# Install R first, then:
pip install rpy2
```

### PDF Export
For PDF export functionality:
```bash
# Requires system cairo libraries
sudo apt install libcairo2-dev  # Debian/Ubuntu
pip install xhtml2pdf
```

### Neo4j Database
For full CKG functionality, you need Neo4j 5.x:
```bash
# Install Neo4j 5.x
# Download database dump from:
# https://data.mendeley.com/datasets/mrcf7f4tc2/1

# Restore and configure:
# Update ckg/graphdb_connector/connector_config.yml
```

## Running the Web App

```bash
source venv/bin/activate
export PYTHONPATH=$PWD

# Start Neo4j first, then:
python3 -m ckg.report_manager.index
```

## Project Structure

```
CKG/
├── ckg/
│   ├── analytics_core/     # Statistics, ML, visualization
│   ├── graphdb_builder/    # Neo4j database builders
│   ├── graphdb_connector/  # Neo4j connection handling
│   └── report_manager/     # Dash web application
├── venv/                   # Python virtual environment
├── setup_ckg.sh           # Quick setup script
├── demo_analytics.py      # Demo without Neo4j
├── requirements_modern.txt # Updated dependencies
└── QUICKSTART.md          # This file
```

## Troubleshooting

### Import Errors
Most import errors are due to missing dependencies:
```bash
pip install <missing_package>
```

### Neo4j Connection Issues
Check `ckg/graphdb_connector/connector_config.yml`:
```yaml
db_url: localhost
db_port: 7687
db_user: neo4j
db_password: your_password
```

### R Functions Not Working
R functions (WGCNA) require R and rpy2 - these are optional.
The warning "WGCNA functions will not work" is expected without R.

## Changes from Original CKG

1. **No Docker Required** - Can run natively with Python venv
2. **Modern Python** - Works with Python 3.10-3.12
3. **Simplified Setup** - Single script installation
4. **Optional Dependencies** - Core works without R, cairo, etc.
5. **Neo4j 5.x Compatible** - Updated driver API

## Contributing

To modernize more of the codebase:
1. Update remaining deprecated patterns
2. Add type hints
3. Improve error handling
4. Add tests

---
CKG 2026 - Modernized Clinical Knowledge Graph
