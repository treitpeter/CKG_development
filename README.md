# alphaCKG

**Modernized Clinical Knowledge Graph**
Updated for Python 3.10+, Neo4j 5.x, and "Batteries Included" ease of use.

## Quick start (local or internal deployment)

The Git repository contains source code and configuration. Database contents,
Neo4j and Redis binaries are **not included**. Installation downloads the service
binaries when missing; loading the knowledge graph is a separate operation.

Prerequisites: Python 3.10+, Java 17 or 21 for Neo4j 5.26, Bash, wget, tar,
and a C compiler/make for Redis. The installer supports Linux. Set `PYTHON`
to a suitable executable if your system Python is older.

### 1. Setup Environment
```bash
read -rs -p 'Choose a Neo4j password: ' CKG_DB_PASSWORD
export CKG_DB_PASSWORD
./install.sh
# Example when python3 is too old:
# PYTHON=/path/to/python3.12 ./install.sh
```
*What this does:*
- Creates/updates `venv` and installs CKG with its declared Python dependencies.
- Downloads Neo4j and compiles Redis if absent; preserves existing installations.
- Creates runtime directories and preserves existing connector credentials.
- Sets the configured initial password only for a newly downloaded Neo4j database.

### 2. Start Services
```bash
./start.sh start
```
*Services started:*
- **Web App**: http://localhost:5000 (binds to loopback; use SSH forwarding on HPC)
- **Neo4j Browser**: http://localhost:7474
  - User: `neo4j`
  - Password: your deployment-specific `CKG_DB_PASSWORD` value

`./start.sh status` reports all three services and returns a nonzero exit code
if any is stopped. `./start.sh stop` stops the web process and workers owned by
this checkout. Redis is stopped only if this launcher started it; a reused Redis
instance is left running. Startup verifies Neo4j connectivity and the web page
before reporting success. Logs are in `log/`.

## 📂 Project Structure

- `ckg/`: **Core Source Code** - Main Python package.
- `data/`: **Data Storage** - Runtime databases, experiments, and ontologies (not versioned).
- `neo4j/`: **Graph Database** - Local Neo4j installation (created by the installer).
- `redis/`: **Cache** - Local Redis build (created by the installer).
- `scripts/`: **Utilities**
    - `build_database_graceful.py`: Database builder with per-source error handling.
    - `utils/`: Maintenance scripts (e.g., database builders).
- `demo_queries.cypher`: **Examples** - Copy-pasteable Cypher queries for Neo4j.

## 🔧 Configuration
Bundled paths resolve against this checkout, independently of the working
directory. Set `CKG_ROOT` to relocate runtime data/logs, or `CKG_CONFIG_FILE`
to select your own YAML configuration. Existing absolute paths remain valid.
Package resources remain with the installed code. For ports or credentials:
- `ckg/graphdb_connector/connector_config.yml`
- `neo4j/neo4j-community-5.26.0/conf/neo4j.conf`

The connector also accepts `CKG_DB_URL`, `CKG_DB_PORT`, `CKG_DB_USER`, and
`CKG_DB_PASSWORD`. Before a first installation, set `CKG_DB_PASSWORD` to your
own password (at least eight characters); no password is shipped in the
configuration. Use the same environment for installation and startup.
Changing connector credentials does not change an existing database password.
Redis currently uses localhost:6379 in both the application and Celery.

For Python-only installation with services managed separately:

```bash
python3 -m venv venv
source venv/bin/activate
python -m pip install -e '.[test]'
python -m pytest -q
python test_ckg.py
python -m build
```

The default pytest suite requires no live database. Historical third-party
database URL checks are opt-in: `python -m pytest --run-network`.
The standalone smoke script checks imports and basic library operations; it
does not validate scientific results or a populated graph. R/rpy2/WGCNA and
cyjupyter are optional integrations requiring separate installation. Plotly
image export with current Kaleido also requires a compatible browser.

Deployment-specific scheduler scripts and legacy container recipes are excluded
from this public tree. Configure your scheduler and services for your own system.

## 📝 Credits
Based on the original [MannLabs/CKG](https://github.com/MannLabs/CKG).
Modernized by Peter, Claude & Gemini.
