#!/bin/bash
# Gemini alphaCKG Launcher
# Starts Neo4j, Redis, and the CKG Web App

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Configuration
NEO4J_VER="5.26.0"
NEO4J_BIN="$SCRIPT_DIR/neo4j/neo4j-community-${NEO4J_VER}/bin/neo4j"
REDIS_SERVER="$SCRIPT_DIR/redis/redis-stable/src/redis-server"
REDIS_CLI="$SCRIPT_DIR/redis/redis-stable/src/redis-cli"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

check_process() {
    if pgrep -f "$1" > /dev/null; then
        echo -e "${GREEN}RUNNING${NC}"
        return 0
    else
        echo -e "${RED}STOPPED${NC}"
        return 1
    fi
}

start() {
    echo "Starting alphaCKG services..."
    
    # 1. Redis
    echo -n "Starting Redis... "
    if [ -x "$REDIS_SERVER" ]; then
        $REDIS_SERVER --daemonize yes > /dev/null 2>&1
        echo "Done."
    else
        echo "ERROR: Redis binary not found. Run ./install.sh"
        exit 1
    fi

    # 2. Neo4j
    echo -n "Starting Neo4j... "
    if [ -x "$NEO4J_BIN" ]; then
        $NEO4J_BIN start > /dev/null 2>&1
        echo "Done (waiting for readiness...)"
        
        # Wait for Neo4j
        n=0
        until [ $n -ge 60 ]
        do
            $NEO4J_BIN status > /dev/null 2>&1 && break
            n=$[$n+1]
            sleep 1
        done
    else
        echo "ERROR: Neo4j binary not found. Run ./install.sh"
        exit 1
    fi

    # 3. Web App
    echo -n "Starting CKG Web App... "
    source venv/bin/activate
    export PYTHONPATH="$SCRIPT_DIR"
    
    # Stop existing
    pkill -f "ckg.report_manager.index" || true
    
    # Start new
    nohup python3 -m ckg.report_manager.index > ckg_web.log 2>&1 &
    echo "Done."
    
    echo ""
    echo -e "${GREEN}System is UP!${NC}"
    echo "  Web App: http://localhost:5000"
    echo "  Neo4j:   http://localhost:7474 (user: neo4j, pass: ckg_password)"
    echo "  Logs:    ckg_web.log"
}

stop() {
    echo "Stopping services..."
    pkill -f "ckg.report_manager.index" || true
    if [ -x "$NEO4J_BIN" ]; then $NEO4J_BIN stop; fi
    if [ -x "$REDIS_CLI" ]; then $REDIS_CLI shutdown; fi
    echo "Services stopped."
}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        stop
        sleep 2
        start
        ;;
    status)
        echo -n "Redis: "
        check_process "redis-server"
        echo -n "Neo4j: "
        check_process "neo4j"
        echo -n "CKG Web: "
        check_process "ckg.report_manager.index"
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac
