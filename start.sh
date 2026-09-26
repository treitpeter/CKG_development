#!/bin/bash
# Manage services belonging to this checkout.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
NEO4J_BIN="$SCRIPT_DIR/neo4j/neo4j-community-5.26.0/bin/neo4j"
REDIS_SERVER="$SCRIPT_DIR/redis/redis-stable/src/redis-server"
REDIS_CLI="$SCRIPT_DIR/redis/redis-stable/src/redis-cli"
PYTHON="$SCRIPT_DIR/venv/bin/python"
RUN_DIR="$SCRIPT_DIR/run"
WEB_PID="$RUN_DIR/web.pid"
REDIS_PID="$RUN_DIR/redis.pid"

web_running() {
    [[ -f "$WEB_PID" ]] || return 1
    local pid args
    read -r pid < "$WEB_PID"
    [[ "$pid" =~ ^[0-9]+$ ]] || return 1
    args=$(ps -p "$pid" -o args=) || return 1
    [[ "$args" == "$PYTHON -m ckg.report_manager.index" ]]
}

redis_running() {
    [[ -x "$REDIS_CLI" ]] && [[ "$("$REDIS_CLI" -h 127.0.0.1 ping 2>/dev/null)" == PONG ]]
}

start() {
    for binary in "$PYTHON" "$REDIS_SERVER" "$REDIS_CLI" "$NEO4J_BIN"; do
        [[ -x "$binary" ]] || { echo "Missing $binary. Run ./install.sh" >&2; return 1; }
    done
    mkdir -p "$RUN_DIR" "$SCRIPT_DIR/log"
    if ! redis_running; then
        "$REDIS_SERVER" --bind 127.0.0.1 --daemonize yes --pidfile "$REDIS_PID" --dir "$RUN_DIR" --logfile "$SCRIPT_DIR/log/redis.log"
        redis_running || { echo "Redis failed to start; see log/redis.log" >&2; return 1; }
    fi
    if ! "$NEO4J_BIN" status >/dev/null 2>&1; then
        "$NEO4J_BIN" start
    fi
    # A running JVM is not proof that Bolt authentication works.
    "$PYTHON" - <<'PY'
import time
from neo4j import GraphDatabase
from ckg.graphdb_connector.connector import read_config
config = read_config()
error = None
for _ in range(30):
    try:
        with GraphDatabase.driver(
            f"bolt://{config['db_url']}:{config['db_port']}",
            auth=(config['db_user'], config['db_password']),
            connection_timeout=2, connection_acquisition_timeout=2,
        ) as driver:
            driver.verify_connectivity()
        break
    except Exception as exc:
        error = exc
        time.sleep(1)
else:
    raise SystemExit(f"Neo4j is not ready: {error}")
PY
    if ! web_running; then
        nohup "$PYTHON" -m ckg.report_manager.index > "$SCRIPT_DIR/log/ckg_web.log" 2>&1 &
        echo "$!" > "$WEB_PID"
    fi
    for ((attempt=0; attempt<60; attempt++)); do
        web_running || { echo "CKG exited; see log/ckg_web.log" >&2; return 1; }
        if "$PYTHON" -c 'from urllib.request import urlopen; urlopen("http://127.0.0.1:5000/", timeout=1)' >/dev/null 2>&1; then
            echo "CKG: http://localhost:5000 | Neo4j: http://localhost:7474"
            return 0
        fi
        sleep 1
    done
    echo "CKG did not become ready; see log/ckg_web.log" >&2
    return 1
}

stop() {
    if web_running; then
        kill "$(cat "$WEB_PID")"
        for ((attempt=0; attempt<35; attempt++)); do
            web_running || break
            sleep 1
        done
        if web_running; then
            echo "CKG has not stopped; see log/ckg_web.log" >&2
            return 1
        fi
    fi
    [[ ! -x "$NEO4J_BIN" ]] || "$NEO4J_BIN" stop
    # A reused Redis instance belongs to its original owner; leave it running.
    if [[ -f "$REDIS_PID" ]] && redis_running; then
        local pid actual
        read -r pid < "$REDIS_PID"
        actual=$("$REDIS_CLI" -h 127.0.0.1 --raw info server | tr -d '\r' | sed -n 's/^process_id://p')
        if [[ "$pid" =~ ^[0-9]+$ && "$pid" == "$actual" ]]; then
            "$REDIS_CLI" -h 127.0.0.1 shutdown
        fi
    fi
}

status() {
    local result=0
    if redis_running; then echo 'Redis: RUNNING'; else echo 'Redis: STOPPED'; result=1; fi
    if [[ -x "$NEO4J_BIN" ]] && "$NEO4J_BIN" status >/dev/null 2>&1; then echo 'Neo4j: RUNNING'; else echo 'Neo4j: STOPPED'; result=1; fi
    if web_running; then echo 'CKG Web: RUNNING'; else echo 'CKG Web: STOPPED'; result=1; fi
    return "$result"
}

case "${1:-}" in
    start) start ;;
    stop) stop ;;
    restart) stop; start ;;
    status) status ;;
    *) echo "Usage: $0 {start|stop|restart|status}" >&2; exit 1 ;;
esac
