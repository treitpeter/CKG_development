# alphaCKG (Gemini Edition)

**Modernized Clinical Knowledge Graph**
Updated for Python 3.10+, Neo4j 5.x, and "Batteries Included" ease of use.

## 🚀 Quick Start (Internal Deployment)

This version is pre-packaged with all required databases and binaries for the Mann Labs HPC cluster.

### 1. Setup Environment
```bash
./install.sh
```
*What this does:*
- Creates/Updates the Python virtual environment (`venv`)
- Verifies local Neo4j and Redis installations (pre-packaged)
- Ensures configuration is correct

### 2. Start Services
```bash
./start.sh start
```
*Services started:*
- **Web App**: http://localhost:5000
- **Neo4j Browser**: http://localhost:7474
  - User: `neo4j`
  - Password: `ckg_password`

## 📂 Project Structure
- `ckg/`: Core source code
- `data/`: Pre-loaded databases and ontologies
- `neo4j/`: Pre-configured Neo4j 5.x
- `redis/`: Pre-compiled Redis
- `install.sh`: Environment setup script
- `start.sh`: Service manager (start/stop/status)

## 🔧 Configuration
The system is pre-configured. If you need to change ports or passwords:
- `ckg/graphdb_connector/connector_config.yml`
- `neo4j/neo4j-community-5.26.0/conf/neo4j.conf`

## 📝 Credits
Based on the original [MannLabs/CKG](https://github.com/MannLabs/CKG).
Modernized by Peter, Claude & Gemini.
