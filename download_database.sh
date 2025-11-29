#!/bin/bash
# Download the pre-built CKG database dump
# WARNING: This is ~30GB and takes time!

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

NEO4J_HOME="$SCRIPT_DIR/neo4j/neo4j-community-5.26.0"
BACKUP_DIR="$SCRIPT_DIR/neo4j_backup"

echo "=========================================="
echo "CKG Database Download"
echo "=========================================="
echo ""
echo "This will download the pre-built Neo4j database (~30GB)"
echo "Note: The dump is for Neo4j 4.2.3 and may need migration"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled"
    exit 1
fi

mkdir -p "$BACKUP_DIR"

echo ""
echo "Downloading database dump (this may take 10-30 minutes)..."
wget -O "$BACKUP_DIR/ckg_4.2.3.dump" \
    "https://datashare.biochem.mpg.de/s/kCW7uKZYTfN8mwg/download" \
    --progress=bar:force

echo ""
echo "Download complete!"
echo ""
echo "To use this dump, you'll need to either:"
echo "1. Install Neo4j 4.2.x and restore directly"
echo "2. Use neo4j-admin to migrate to Neo4j 5.x"
echo ""
echo "Migration command (after stopping Neo4j):"
echo "  neo4j-admin database migrate --from-path=$BACKUP_DIR/ckg_4.2.3.dump neo4j"
echo ""
echo "Or for a fresh build from source data, use:"
echo "  PYTHONPATH=. python3 -c 'from ckg.graphdb_builder.builder import builder; builder.run_full_update()'"
