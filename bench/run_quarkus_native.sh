#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
NATIVE_BINARY="$ROOT_DIR/quarkus-todo/target/quarkus-todo-1.0.0-SNAPSHOT-runner"

if [ ! -f "$NATIVE_BINARY" ]; then
    echo "Error: Native binary not found at $NATIVE_BINARY"
    echo "Please run './build_native.sh' first"
    exit 1
fi

echo "Starting Quarkus Native application..."
cd "$ROOT_DIR"

# Native実行なので、JVMオプションは不要
"$NATIVE_BINARY" -Dquarkus.http.port=8081 > logs/quarkus-native.log 2>&1 &
PID=$!

echo $PID > "$SCRIPT_DIR/quarkus-native.pid"
echo "Quarkus Native started with PID: $PID"
echo "Log file: logs/quarkus-native.log"
