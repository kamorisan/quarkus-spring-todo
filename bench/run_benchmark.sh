#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo "========================================="
echo "  Quarkus vs Spring Boot Benchmark"
echo "  (3-Way Comparison)"
echo "========================================="
echo ""

# ビルド成果物の事前確認
echo "Checking build artifacts..."
QUARKUS_NATIVE="$ROOT_DIR/quarkus-todo/target/quarkus-todo-1.0.0-SNAPSHOT-runner"
QUARKUS_JVM="$ROOT_DIR/quarkus-todo/target/quarkus-app/quarkus-run.jar"
SPRING_JVM="$ROOT_DIR/spring-todo/target/spring-todo-0.0.1-SNAPSHOT.jar"

HAS_NATIVE=false
HAS_QUARKUS_JVM=false
HAS_SPRING_JVM=false

[ -f "$QUARKUS_NATIVE" ] && HAS_NATIVE=true
[ -f "$QUARKUS_JVM" ] && HAS_QUARKUS_JVM=true
[ -f "$SPRING_JVM" ] && HAS_SPRING_JVM=true

echo "  Quarkus Native: $([ "$HAS_NATIVE" = true ] && echo "✅ Found" || echo "❌ Not found")"
echo "  Quarkus JVM:    $([ "$HAS_QUARKUS_JVM" = true ] && echo "✅ Found" || echo "❌ Not found")"
echo "  Spring JVM:     $([ "$HAS_SPRING_JVM" = true ] && echo "✅ Found" || echo "❌ Not found")"
echo ""

if [ "$HAS_QUARKUS_JVM" = false ] || [ "$HAS_SPRING_JVM" = false ]; then
    echo "Error: Missing required build artifacts."
    echo ""
    echo "Please run the build script first:"
    echo "  ./build_all.sh"
    echo ""
    exit 1
fi

echo "This benchmark will measure:"
if [ "$HAS_NATIVE" = true ]; then
    echo "  1. Quarkus Native Image ⚡"
    echo "  2. Quarkus JVM"
    echo "  3. Spring Boot JVM"
else
    echo "  1. Quarkus JVM (Native skipped)"
    echo "  2. Spring Boot JVM"
fi
echo ""

# ログディレクトリを作成
mkdir -p "$ROOT_DIR/logs"
mkdir -p "$ROOT_DIR/results"

# 既存のプロセスをクリーンアップ
cleanup_processes() {
    for pidfile in quarkus-native.pid quarkus.pid spring.pid; do
        if [ -f "$SCRIPT_DIR/$pidfile" ]; then
            PID=$(cat "$SCRIPT_DIR/$pidfile")
            if ps -p $PID > /dev/null 2>&1; then
                echo "Stopping existing process (PID: $PID)..."
                kill $PID
                sleep 2
            fi
            rm "$SCRIPT_DIR/$pidfile"
        fi
    done
}

cleanup_processes

# Quarkus Nativeバイナリの確認
NATIVE_BINARY="$ROOT_DIR/quarkus-todo/target/quarkus-todo-1.0.0-SNAPSHOT-runner"
SKIP_NATIVE=false

if [ ! -f "$NATIVE_BINARY" ]; then
    echo "Warning: Quarkus Native binary not found."
    echo "Skipping Quarkus Native benchmark."
    echo "To build native image for macOS, run: ./build_native_macos.sh"
    echo ""
    SKIP_NATIVE=true
else
    # バイナリの実行可能性をチェック
    BINARY_TYPE=$(file "$NATIVE_BINARY" | grep -o "Mach-O\|ELF")

    if [ "$BINARY_TYPE" = "ELF" ]; then
        echo "Warning: Native binary is a Linux executable (ELF)."
        echo "This was built with Docker and cannot run on macOS."
        echo "Skipping Quarkus Native benchmark."
        echo ""
        echo "To build for macOS:"
        echo "  ./build_native_macos.sh"
        echo ""
        echo "Or continue with 2-way benchmark (Quarkus JVM vs Spring JVM)"
        echo ""
        SKIP_NATIVE=true
    fi
fi

# ========================================
# 1. Quarkus Native Image
# ========================================
if [ "$SKIP_NATIVE" = false ]; then
    echo ""
    echo "========================================="
    echo "  1/3: Testing Quarkus Native Image"
    echo "========================================="
    echo ""

    # データディレクトリをクリーンアップ
    echo "Cleaning up data directory..."
    rm -rf "$ROOT_DIR/data"

    # Quarkus Nativeを起動
    bash "$SCRIPT_DIR/run_quarkus_native.sh"
    sleep 2

    # Ready待機
    bash "$SCRIPT_DIR/wait_ready.sh" "http://localhost:8081/health/ready"

    # アイドル計測
    QUARKUS_NATIVE_PID=$(cat "$SCRIPT_DIR/quarkus-native.pid")
    echo "Measuring idle metrics for 60 seconds..."
    bash "$SCRIPT_DIR/measure_idle.sh" "$QUARKUS_NATIVE_PID" 60 "$ROOT_DIR/results/quarkus-native_idle.csv"

    # 停止
    echo "Stopping Quarkus Native..."
    kill $QUARKUS_NATIVE_PID
    sleep 3
else
    echo ""
    echo "========================================="
    echo "  1/3: Skipping Quarkus Native Image"
    echo "========================================="
    echo ""
fi

# ========================================
# 2. Quarkus JVM
# ========================================
echo ""
echo "========================================="
echo "  2/3: Testing Quarkus JVM"
echo "========================================="
echo ""

# データディレクトリをクリーンアップ
echo "Cleaning up data directory..."
rm -rf "$ROOT_DIR/data"

# Quarkus JVMを起動
bash "$SCRIPT_DIR/run_quarkus.sh"
sleep 2

# Ready待機
bash "$SCRIPT_DIR/wait_ready.sh" "http://localhost:8081/health/ready"

# アイドル計測
QUARKUS_PID=$(cat "$SCRIPT_DIR/quarkus.pid")
echo "Measuring idle metrics for 60 seconds..."
bash "$SCRIPT_DIR/measure_idle.sh" "$QUARKUS_PID" 60 "$ROOT_DIR/results/quarkus_idle.csv"

# 停止
echo "Stopping Quarkus JVM..."
kill $QUARKUS_PID
sleep 3

# ========================================
# 3. Spring Boot JVM
# ========================================
echo ""
echo "========================================="
echo "  3/3: Testing Spring Boot JVM"
echo "========================================="
echo ""

# データディレクトリをクリーンアップ
echo "Cleaning up data directory..."
rm -rf "$ROOT_DIR/data"

# Spring Bootを起動
bash "$SCRIPT_DIR/run_spring.sh"
sleep 2

# Ready待機
bash "$SCRIPT_DIR/wait_ready.sh" "http://localhost:8082/health/ready"

# アイドル計測
SPRING_PID=$(cat "$SCRIPT_DIR/spring.pid")
echo "Measuring idle metrics for 60 seconds..."
bash "$SCRIPT_DIR/measure_idle.sh" "$SPRING_PID" 60 "$ROOT_DIR/results/spring_idle.csv"

# 停止
echo "Stopping Spring Boot JVM..."
kill $SPRING_PID
sleep 3

echo ""
echo "========================================="
echo "  Benchmark Complete"
echo "========================================="
echo ""

# サマリー表示
bash "$SCRIPT_DIR/summary.sh"
