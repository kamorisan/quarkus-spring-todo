#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_DIR="$SCRIPT_DIR/../results"

echo "========================================="
echo "  Quarkus vs Spring Boot Benchmark Summary"
echo "========================================="
echo ""

# Quarkus起動時間
if [ -f "$SCRIPT_DIR/../logs/quarkus.log" ]; then
    QUARKUS_READY=$(grep "APP_READY_MS" "$SCRIPT_DIR/../logs/quarkus.log" | tail -1 | grep -oE '[0-9]+')
    if [ -n "$QUARKUS_READY" ]; then
        echo "Quarkus Startup Time: ${QUARKUS_READY}ms"
    fi
fi

# Spring起動時間
if [ -f "$SCRIPT_DIR/../logs/spring.log" ]; then
    SPRING_READY=$(grep "APP_READY_MS" "$SCRIPT_DIR/../logs/spring.log" | tail -1 | grep -oE '[0-9]+')
    if [ -n "$SPRING_READY" ]; then
        echo "Spring Boot Startup Time: ${SPRING_READY}ms"
    fi
fi

echo ""
echo "-----------------------------------------"
echo "Memory Usage (Idle)"
echo "-----------------------------------------"

# Quarkus メモリ
if [ -f "$RESULTS_DIR/quarkus_idle.csv" ]; then
    QUARKUS_MAX_RSS=$(tail -n +2 "$RESULTS_DIR/quarkus_idle.csv" | cut -d, -f2 | sort -n | tail -1)
    QUARKUS_AVG_RSS=$(tail -n +2 "$RESULTS_DIR/quarkus_idle.csv" | cut -d, -f2 | awk '{sum+=$1; count++} END {if(count>0) print int(sum/count)}')
    echo "Quarkus Max RSS: ${QUARKUS_MAX_RSS} KB ($(echo "scale=2; $QUARKUS_MAX_RSS / 1024" | bc) MB)"
    echo "Quarkus Avg RSS: ${QUARKUS_AVG_RSS} KB ($(echo "scale=2; $QUARKUS_AVG_RSS / 1024" | bc) MB)"
fi

# Spring メモリ
if [ -f "$RESULTS_DIR/spring_idle.csv" ]; then
    SPRING_MAX_RSS=$(tail -n +2 "$RESULTS_DIR/spring_idle.csv" | cut -d, -f2 | sort -n | tail -1)
    SPRING_AVG_RSS=$(tail -n +2 "$RESULTS_DIR/spring_idle.csv" | cut -d, -f2 | awk '{sum+=$1; count++} END {if(count>0) print int(sum/count)}')
    echo "Spring Boot Max RSS: ${SPRING_MAX_RSS} KB ($(echo "scale=2; $SPRING_MAX_RSS / 1024" | bc) MB)"
    echo "Spring Boot Avg RSS: ${SPRING_AVG_RSS} KB ($(echo "scale=2; $SPRING_AVG_RSS / 1024" | bc) MB)"
fi

echo ""
echo "-----------------------------------------"
echo "CPU Usage (Idle)"
echo "-----------------------------------------"

# Quarkus CPU
if [ -f "$RESULTS_DIR/quarkus_idle.csv" ]; then
    QUARKUS_MAX_CPU=$(tail -n +2 "$RESULTS_DIR/quarkus_idle.csv" | cut -d, -f3 | sort -n | tail -1)
    QUARKUS_AVG_CPU=$(tail -n +2 "$RESULTS_DIR/quarkus_idle.csv" | cut -d, -f3 | awk '{sum+=$1; count++} END {if(count>0) printf "%.2f", sum/count}')
    echo "Quarkus Max CPU: ${QUARKUS_MAX_CPU}%"
    echo "Quarkus Avg CPU: ${QUARKUS_AVG_CPU}%"
fi

# Spring CPU
if [ -f "$RESULTS_DIR/spring_idle.csv" ]; then
    SPRING_MAX_CPU=$(tail -n +2 "$RESULTS_DIR/spring_idle.csv" | cut -d, -f3 | sort -n | tail -1)
    SPRING_AVG_CPU=$(tail -n +2 "$RESULTS_DIR/spring_idle.csv" | cut -d, -f3 | awk '{sum+=$1; count++} END {if(count>0) printf "%.2f", sum/count}')
    echo "Spring Boot Max CPU: ${SPRING_MAX_CPU}%"
    echo "Spring Boot Avg CPU: ${SPRING_AVG_CPU}%"
fi

echo ""
echo "========================================="
