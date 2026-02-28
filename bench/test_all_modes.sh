#!/bin/bash

# Test all three modes (Native, Quarkus JVM, Spring JVM)
# This script starts each server, runs tests, then stops it

set -e

echo "========================================="
echo "  API Tests for All Modes"
echo "  (3-Way Test Runner)"
echo "========================================="
echo ""

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Check for required files
QUARKUS_NATIVE="$PROJECT_ROOT/quarkus-todo/target/quarkus-todo-1.0.0-SNAPSHOT-runner"
QUARKUS_JVM="$PROJECT_ROOT/quarkus-todo/target/quarkus-app/quarkus-run.jar"
SPRING_JVM="$PROJECT_ROOT/spring-todo/target/spring-todo-0.0.1-SNAPSHOT.jar"

HAS_NATIVE=false
HAS_QUARKUS_JVM=false
HAS_SPRING_JVM=false

[ -f "$QUARKUS_NATIVE" ] && HAS_NATIVE=true
[ -f "$QUARKUS_JVM" ] && HAS_QUARKUS_JVM=true
[ -f "$SPRING_JVM" ] && HAS_SPRING_JVM=true

echo "Available modes:"
echo "  Quarkus Native: $($HAS_NATIVE && echo "✓" || echo "✗")"
echo "  Quarkus JVM:    $($HAS_QUARKUS_JVM && echo "✓" || echo "✗")"
echo "  Spring JVM:     $($HAS_SPRING_JVM && echo "✓" || echo "✗")"
echo ""

if ! $HAS_NATIVE && ! $HAS_QUARKUS_JVM && ! $HAS_SPRING_JVM; then
    echo "Error: No build artifacts found"
    echo "Run ./build_all.sh first"
    exit 1
fi

# Helper function to wait for server
wait_for_server() {
    local port=$1
    local max_wait=30
    local count=0

    while [ $count -lt $max_wait ]; do
        if curl -s -f "http://localhost:$port/q/health/ready" > /dev/null 2>&1 || \
           curl -s -f "http://localhost:$port/actuator/health" > /dev/null 2>&1; then
            return 0
        fi
        sleep 1
        count=$((count + 1))
    done
    return 1
}

# Test Quarkus Native
if $HAS_NATIVE; then
    echo "========================================="
    echo "  Testing Quarkus Native"
    echo "========================================="
    echo ""

    echo "Starting Quarkus Native..."
    "$QUARKUS_NATIVE" > /tmp/quarkus-native-test.log 2>&1 &
    NATIVE_PID=$!

    if wait_for_server 8081; then
        echo "Running tests..."
        "$SCRIPT_DIR/smoke_test.sh" 8081
        echo ""
    else
        echo "Failed to start Quarkus Native"
        kill $NATIVE_PID 2>/dev/null || true
        exit 1
    fi

    echo "Stopping Quarkus Native..."
    kill $NATIVE_PID 2>/dev/null || true
    wait $NATIVE_PID 2>/dev/null || true
    sleep 2
    echo ""
fi

# Test Quarkus JVM
if $HAS_QUARKUS_JVM; then
    echo "========================================="
    echo "  Testing Quarkus JVM"
    echo "========================================="
    echo ""

    echo "Starting Quarkus JVM..."
    java -Xms128m -Xmx512m -jar "$QUARKUS_JVM" > /tmp/quarkus-jvm-test.log 2>&1 &
    JVM_PID=$!

    if wait_for_server 8081; then
        echo "Running tests..."
        "$SCRIPT_DIR/smoke_test.sh" 8081
        echo ""
    else
        echo "Failed to start Quarkus JVM"
        kill $JVM_PID 2>/dev/null || true
        exit 1
    fi

    echo "Stopping Quarkus JVM..."
    kill $JVM_PID 2>/dev/null || true
    wait $JVM_PID 2>/dev/null || true
    sleep 2
    echo ""
fi

# Test Spring Boot JVM
if $HAS_SPRING_JVM; then
    echo "========================================="
    echo "  Testing Spring Boot JVM"
    echo "========================================="
    echo ""

    echo "Starting Spring Boot..."
    java -Xms128m -Xmx512m -jar "$SPRING_JVM" > /tmp/spring-jvm-test.log 2>&1 &
    SPRING_PID=$!

    if wait_for_server 8082; then
        echo "Running tests..."
        "$SCRIPT_DIR/smoke_test.sh" 8082
        echo ""
    else
        echo "Failed to start Spring Boot"
        kill $SPRING_PID 2>/dev/null || true
        exit 1
    fi

    echo "Stopping Spring Boot..."
    kill $SPRING_PID 2>/dev/null || true
    wait $SPRING_PID 2>/dev/null || true
    sleep 2
    echo ""
fi

echo "========================================="
echo "  All Tests Complete!"
echo "========================================="
echo ""
echo "All modes passed smoke tests ✓"
echo ""
