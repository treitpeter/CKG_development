#!/bin/bash
# Start Neo4j in console mode (shows output in terminal)
# Usage: ./start_neo4j.sh [console|start|stop|status]

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
NEO4J_HOME="$SCRIPT_DIR/neo4j/neo4j-community-5.26.0"

export JAVA_HOME="${JAVA_HOME:-/usr}"
export NEO4J_HOME

ACTION="${1:-console}"

case "$ACTION" in
    console)
        echo "Starting Neo4j in console mode (Ctrl+C to stop)..."
        echo "Web interface: http://localhost:7474"
        echo "Bolt port: localhost:7687"
        echo ""
        $NEO4J_HOME/bin/neo4j console
        ;;
    start)
        echo "Starting Neo4j as background service..."
        $NEO4J_HOME/bin/neo4j start
        echo "Check status with: ./start_neo4j.sh status"
        ;;
    stop)
        echo "Stopping Neo4j..."
        $NEO4J_HOME/bin/neo4j stop
        ;;
    status)
        $NEO4J_HOME/bin/neo4j status
        ;;
    *)
        echo "Usage: $0 {console|start|stop|status}"
        echo ""
        echo "  console - Run in foreground (recommended for development)"
        echo "  start   - Run as background service"
        echo "  stop    - Stop the service"
        echo "  status  - Check if running"
        exit 1
        ;;
esac
