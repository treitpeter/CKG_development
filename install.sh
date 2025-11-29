#!/bin/bash
set -e

# Gemini alphaCKG Installer
# Sets up Python, Neo4j, Redis, and directory structure.

echo "=============================================="
echo "       alphaCKG Installer (Gemini Edition)    "
echo "=============================================="

# 1. Environment Setup
echo "[1/4] Setting up Python environment..."
if [ ! -d "venv" ]; then
    python3 -m venv venv
    echo "      Created venv."
else
    echo "      venv exists."
fi

source venv/bin/activate
pip install --upgrade pip wheel -q
if [ -f "requirements_modern.txt" ]; then
    echo "      Installing Python dependencies (this may take a few minutes)..."
    pip install -r requirements_modern.txt -q
    echo "      Python dependencies installed."
else
    echo "ERROR: requirements_modern.txt not found!"
    exit 1
fi

# 2. Redis Setup
echo "[2/4] Verifying/Setting up Redis..."
REDIS_DIR="redis"
REDIS_VER="7.2.4"
REDIS_SERVER_PATH="$REDIS_DIR/redis-stable/src/redis-server"

if [ ! -f "$REDIS_SERVER_PATH" ]; then
    echo "      Redis binary not found. Downloading and compiling Redis $REDIS_VER..."
    mkdir -p "$REDIS_DIR"
    wget -qc http://download.redis.io/releases/redis-${REDIS_VER}.tar.gz -O redis.tar.gz
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
    echo "      Neo4j installation not found. Downloading and configuring Neo4j Community $NEO4J_VER..."
    mkdir -p "$NEO4J_DIR"
    wget -qc "https://neo4j.com/artifact.php?name=neo4j-community-${NEO4J_VER}-unix.tar.gz" -O neo4j.tar.gz
    tar xzf neo4j.tar.gz -C "$NEO4J_DIR"
    rm neo4j.tar.gz
    
    # Configure Neo4j
    echo "      Configuring Neo4j..."
    CONF="$NEO4J_HOME/conf/neo4j.conf"
    
    # Allow remote access
    sed -i 's/#server.default_listen_address=0.0.0.0/server.default_listen_address=0.0.0.0/' "$CONF"
    
    # Increase memory
    echo "" >> "$CONF"
    echo "# alphaCKG Optimizations" >> "$CONF"
    echo "server.memory.heap.initial_size=2g" >> "$CONF"
    echo "server.memory.heap.max_size=8g" >> "$CONF"
    echo "server.memory.pagecache.size=4g" >> "$CONF"
    
    # Allow imports from anywhere (comment out restriction)
    sed -i 's/server.directories.import=import/#server.directories.import=import/' "$CONF"
    
    echo "      Neo4j installed and configured."
else
    echo "      Neo4j installation found. Skipping download."
    # Ensure config is applied if not already
    CONF="$NEO4J_HOME/conf/neo4j.conf"
    if ! grep -q "server.default_listen_address=0.0.0.0" "$CONF"; then
        echo "      Applying Neo4j configuration for pre-existing install..."
        sed -i 's/#server.default_listen_address=0.0.0.0/server.default_listen_address=0.0.0.0/' "$CONF"
        echo "" >> "$CONF"
        echo "# alphaCKG Optimizations" >> "$CONF"
        echo "server.memory.heap.initial_size=2g" >> "$CONF"
        echo "server.memory.heap.max_size=8g" >> "$CONF"
        echo "server.memory.pagecache.size=4g" >> "$CONF"
        sed -i 's/server.directories.import=import/#server.directories.import=import/' "$CONF"
    fi
fi

# 4. CKG Configuration
echo "[4/4] Initializing CKG Configuration and Directories..."
# Ensure config file exists
if [ ! -f "ckg/graphdb_connector/connector_config.yml" ]; then
    echo "      Creating default connector_config.yml..."
    cat > ckg/graphdb_connector/connector_config.yml <<EOF
db_url: "localhost"
db_port: 7687
db_user: "neo4j"
db_password: "ckg_password"
EOF
else
    echo "      ckg/graphdb_connector/connector_config.yml already exists."
    # Ensure default password is set for pre-existing, if not using a specific one.
    # This might overwrite user's password if they changed it manually.
    # For a "batteries-included" internal setup, this is probably fine if the boss knows it's temporary/default.
    sed -i 's/db_password: ".*/db_password: "ckg_password"/' ckg/graphdb_connector/connector_config.yml
fi

# Create data directories if they don't exist (important for pre-loaded data)
mkdir -p data/databases
mkdir -p data/imports
mkdir -p data/ontologies
mkdir -p log

# Finalize
echo ""
echo "=============================================="
echo "      Installation Complete!                  "
echo "=============================================="
echo "To start the application:"
echo "  ./start.sh start"
echo ""
