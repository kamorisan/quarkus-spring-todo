#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
JAR_PATH="$ROOT_DIR/spring-todo/target/spring-todo-0.0.1-SNAPSHOT.jar"

if [ ! -f "$JAR_PATH" ]; then
    echo "Error: JAR file not found at $JAR_PATH"
    echo "Please run 'mvn package' in spring-todo directory first"
    exit 1
fi

# 共通JVMオプション
JVM_OPTS="-Xms128m -Xmx512m -Dfile.encoding=UTF-8"

echo "Starting Spring Boot application..."
cd "$ROOT_DIR"

java $JVM_OPTS -jar "$JAR_PATH" > logs/spring.log 2>&1 &
PID=$!

echo $PID > "$SCRIPT_DIR/spring.pid"
echo "Spring Boot started with PID: $PID"
echo "Log file: logs/spring.log"
