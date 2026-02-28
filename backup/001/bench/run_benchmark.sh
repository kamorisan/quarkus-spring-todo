#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo "========================================="
echo "  Quarkus vs Spring Boot Benchmark"
echo "========================================="
echo ""

# ログディレクトリを作成
mkdir -p "$ROOT_DIR/logs"
mkdir -p "$ROOT_DIR/results"

# データディレクトリをクリーンアップ
echo "Cleaning up data directory..."
rm -rf "$ROOT_DIR/data"

# 既存のプロセスをクリーンアップ
if [ -f "$SCRIPT_DIR/quarkus.pid" ]; then
    PID=$(cat "$SCRIPT_DIR/quarkus.pid")
    if ps -p $PID > /dev/null 2>&1; then
        echo "Stopping existing Quarkus process (PID: $PID)..."
        kill $PID
        sleep 2
    fi
    rm "$SCRIPT_DIR/quarkus.pid"
fi

if [ -f "$SCRIPT_DIR/spring.pid" ]; then
    PID=$(cat "$SCRIPT_DIR/spring.pid")
    if ps -p $PID > /dev/null 2>&1; then
        echo "Stopping existing Spring Boot process (PID: $PID)..."
        kill $PID
        sleep 2
    fi
    rm "$SCRIPT_DIR/spring.pid"
fi

echo ""
echo "========================================="
echo "  Testing Quarkus"
echo "========================================="
echo ""

# Quarkusを起動
bash "$SCRIPT_DIR/run_quarkus.sh"
sleep 2

# Ready待機
bash "$SCRIPT_DIR/wait_ready.sh" "http://localhost:8081/health/ready"

# アイドル計測
QUARKUS_PID=$(cat "$SCRIPT_DIR/quarkus.pid")
echo "Measuring idle metrics for 60 seconds..."
bash "$SCRIPT_DIR/measure_idle.sh" "$QUARKUS_PID" 60 "$ROOT_DIR/results/quarkus_idle.csv"

# 停止
echo "Stopping Quarkus..."
kill $QUARKUS_PID
sleep 3

# データディレクトリをクリーンアップ
rm -rf "$ROOT_DIR/data"

echo ""
echo "========================================="
echo "  Testing Spring Boot"
echo "========================================="
echo ""

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
echo "Stopping Spring Boot..."
kill $SPRING_PID
sleep 3

echo ""
echo "========================================="
echo "  Benchmark Complete"
echo "========================================="
echo ""

# サマリー表示
bash "$SCRIPT_DIR/summary.sh"
