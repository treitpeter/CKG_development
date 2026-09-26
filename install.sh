#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
PYTHON="${PYTHON:-python3}"
"$PYTHON" -c 'import sys; sys.exit(0 if sys.version_info >= (3, 10) else "Python 3.10+ required; set PYTHON to its executable.")'

# Gemini alphaCKG Installer
# Sets up Python, Neo4j, Redis, and directory structure.

echo "=============================================="
echo "       alphaCKG Installer (Gemini Edition)    "
echo "=============================================="

# 1. Environment Setup
echo "[1/4] Setting up Python environment..."
if [ ! -d "venv" ]; then
    "$PYTHON" -m venv venv
    echo "      Created venv."
else
    echo "      venv exists."
fi

source venv/bin/activate
python -m pip install --upgrade pip wheel
python -m pip install -e .

# 2. Redis Setup
echo "[2/4] Verifying/Setting up Redis..."
REDIS_DIR="redis"
REDIS_VER="7.2.4"
REDIS_SERVER_PATH="$REDIS_DIR/redis-stable/src/redis-server"

if [ ! -f "$REDIS_SERVER_PATH" ]; then
    echo "      Redis binary not found. Downloading and compiling Redis $REDIS_VER..."
    mkdir -p "$REDIS_DIR"
    wget -qc https://download.redis.io/releases/redis-${REDIS_VER}.tar.gz -O redis.tar.gz
    tar xzf redis.tar.gz -C "$REDIS_DIR"
    if [ -d "$REDIS_DIR/redis-${REDIS_VER}" ]; then
        mv "$REDIS_DIR/redis-${REDIS_VER}" "$REDIS_DIR/redis-stable"
    fi
    rm redis.tar.gz
    
    echo "      Compiling Redis (may take a moment)..."
    cd "$REDIS_DIR/redis-stable"
    make -j$(nproc) --quiet
    cd ../..
    echo "      Redis compiled and ready."
else
    echo "      Redis binaries found. Skipping download/compile."
fi

# 3. Neo4j Setup
echo "[3/4] Verifying/Setting up Neo4j..."
NEO4J_VER="5.26.0"
NEO4J_DIR="neo4j"
NEO4J_HOME="$NEO4J_DIR/neo4j-community-${NEO4J_VER}"

if [ ! -d "$NEO4J_HOME" ]; then
    DB_PASSWORD=$(python -c 'from ckg.graphdb_connector.connector import read_config; print(read_config()["db_password"])')
    if [[ ${#DB_PASSWORD} -lt 8 ]]; then
        echo "Set CKG_DB_PASSWORD to a deployment-specific password of at least 8 characters." >&2
        exit 1
    fi
    echo "      Neo4j installation not found. Downloading and configuring Neo4j Community $NEO4J_VER..."
    mkdir -p "$NEO4J_DIR"
    wget -qc "https://neo4j.com/artifact.php?name=neo4j-community-${NEO4J_VER}-unix.tar.gz" -O neo4j.tar.gz
    tar xzf neo4j.tar.gz -C "$NEO4J_DIR"
    rm neo4j.tar.gz
    
    # Configure Neo4j
    echo "      Configuring Neo4j..."
    CONF="$NEO4J_HOME/conf/neo4j.conf"
    
    
    # Increase memory
    echo "" >> "$CONF"
    echo "# alphaCKG Optimizations" >> "$CONF"
    echo "server.memory.heap.initial_size=2g" >> "$CONF"
    echo "server.memory.heap.max_size=8g" >> "$CONF"
    echo "server.memory.pagecache.size=4g" >> "$CONF"
    
    # Allow imports from anywhere (comment out restriction)
    sed -i 's/server.directories.import=import/#server.directories.import=import/' "$CONF"
    
    # Initialize authentication only for a newly downloaded database.
    "$NEO4J_HOME/bin/neo4j-admin" dbms set-initial-password "$DB_PASSWORD"
    echo "      Neo4j installed and configured."
else
    echo "      Neo4j installation found. Skipping download."

fi

# 4. CKG Configuration
echo "[4/4] Initializing CKG Configuration and Directories..."
# Preserve connector credentials and deployment configuration.
python - <<'PYTHON'
from pathlib import Path
from ckg import ckg_utils
for key, value in ckg_utils.read_ckg_config().items():
    if key.endswith('_directory'):
        Path(value).mkdir(parents=True, exist_ok=True)
PYTHON

# Finalize
echo ""
echo "=============================================="
echo "      Installation Complete!                  "
echo "=============================================="
echo "To start the application:"
echo "  ./start.sh start"
echo ""
