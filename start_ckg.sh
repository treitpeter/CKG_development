#!/bin/bash
# Start CKG_PeTr Application
# Make sure Neo4j is running first: ./start_neo4j.sh

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Activate virtual environment
source venv/bin/activate

# Set Python path
export PYTHONPATH="$SCRIPT_DIR"

# Check if Neo4j is reachable
echo "Checking Neo4j connection..."
python3 -c "
from ckg.graphdb_connector import connector
try:
    driver = connector.getGraphDatabaseConnectionConfiguration()
    if driver:
        with driver.session() as session:
            result = session.run('RETURN 1 as test')
            print('  Neo4j connection: OK')
    else:
        print('  Neo4j connection: FAILED (is Neo4j running?)')
        print('  Start Neo4j with: ./start_neo4j.sh')
except Exception as e:
    print(f'  Neo4j connection: FAILED - {e}')
    print('  Start Neo4j with: ./start_neo4j.sh')
" 2>&1 | grep -v "WGCNA\|Rpy2\|R functions"

echo ""
echo "Starting CKG application..."
echo "Web interface will be at: http://localhost:5000"
echo ""

# Start the app
python3 -m ckg.report_manager.index
