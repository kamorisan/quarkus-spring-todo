#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
JAR_PATH="$ROOT_DIR/quarkus-todo/target/quarkus-app/quarkus-run.jar"

if [ ! -f "$JAR_PATH" ]; then
    echo "Error: JAR file not found at $JAR_PATH"
    echo "Please run 'mvn package' in quarkus-todo directory first"
    exit 1
fi

# 共通JVMオプション
JVM_OPTS="-Xms128m -Xmx512m -Dfile.encoding=UTF-8"

echo "Starting Quarkus JVM application..."
cd "$ROOT_DIR"

java $JVM_OPTS -jar "$JAR_PATH" > logs/quarkus.log 2>&1 &
PID=$!

echo $PID > "$SCRIPT_DIR/quarkus.pid"
echo "Quarkus started with PID: $PID"
echo "Log file: logs/quarkus.log"
