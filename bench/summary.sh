#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_DIR="$SCRIPT_DIR/../results"

echo "========================================="
echo "  Quarkus vs Spring Boot Benchmark Summary"
echo "  (3-Way Comparison)"
echo "========================================="
echo ""

# Quarkus Native起動時間
if [ -f "$SCRIPT_DIR/../logs/quarkus-native.log" ]; then
    QUARKUS_NATIVE_READY=$(grep "APP_READY_MS" "$SCRIPT_DIR/../logs/quarkus-native.log" | tail -1 | sed 's/.*APP_READY_MS=\([0-9]*\).*/\1/')
    if [ -n "$QUARKUS_NATIVE_READY" ] && [ "$QUARKUS_NATIVE_READY" != "" ]; then
        echo "Quarkus Native Startup Time: ${QUARKUS_NATIVE_READY}ms"
    fi
fi

# Quarkus JVM起動時間
if [ -f "$SCRIPT_DIR/../logs/quarkus.log" ]; then
    QUARKUS_JVM_READY=$(grep "APP_READY_MS" "$SCRIPT_DIR/../logs/quarkus.log" | tail -1 | sed 's/.*APP_READY_MS=\([0-9]*\).*/\1/')
    if [ -n "$QUARKUS_JVM_READY" ] && [ "$QUARKUS_JVM_READY" != "" ]; then
        echo "Quarkus JVM Startup Time: ${QUARKUS_JVM_READY}ms"
    fi
fi

# Spring起動時間
if [ -f "$SCRIPT_DIR/../logs/spring.log" ]; then
    SPRING_READY=$(grep "APP_READY_MS" "$SCRIPT_DIR/../logs/spring.log" | tail -1 | sed 's/.*APP_READY_MS=\([0-9]*\).*/\1/')
    if [ -n "$SPRING_READY" ]; then
        echo "Spring Boot JVM Startup Time: ${SPRING_READY}ms"
    fi
fi

echo ""
echo "-----------------------------------------"
echo "Memory Usage (Idle)"
echo "-----------------------------------------"

# Quarkus Native メモリ
if [ -f "$RESULTS_DIR/quarkus-native_idle.csv" ]; then
    QUARKUS_NATIVE_MAX_RSS=$(tail -n +2 "$RESULTS_DIR/quarkus-native_idle.csv" | cut -d, -f2 | sort -n | tail -1)
    QUARKUS_NATIVE_AVG_RSS=$(tail -n +2 "$RESULTS_DIR/quarkus-native_idle.csv" | cut -d, -f2 | awk '{sum+=$1; count++} END {if(count>0) print int(sum/count)}')
    echo "Quarkus Native Max RSS: ${QUARKUS_NATIVE_MAX_RSS} KB ($(echo "scale=2; $QUARKUS_NATIVE_MAX_RSS / 1024" | bc) MB)"
    echo "Quarkus Native Avg RSS: ${QUARKUS_NATIVE_AVG_RSS} KB ($(echo "scale=2; $QUARKUS_NATIVE_AVG_RSS / 1024" | bc) MB)"
fi

# Quarkus JVM メモリ
if [ -f "$RESULTS_DIR/quarkus_idle.csv" ]; then
    QUARKUS_JVM_MAX_RSS=$(tail -n +2 "$RESULTS_DIR/quarkus_idle.csv" | cut -d, -f2 | sort -n | tail -1)
    QUARKUS_JVM_AVG_RSS=$(tail -n +2 "$RESULTS_DIR/quarkus_idle.csv" | cut -d, -f2 | awk '{sum+=$1; count++} END {if(count>0) print int(sum/count)}')
    echo "Quarkus JVM Max RSS: ${QUARKUS_JVM_MAX_RSS} KB ($(echo "scale=2; $QUARKUS_JVM_MAX_RSS / 1024" | bc) MB)"
    echo "Quarkus JVM Avg RSS: ${QUARKUS_JVM_AVG_RSS} KB ($(echo "scale=2; $QUARKUS_JVM_AVG_RSS / 1024" | bc) MB)"
fi

# Spring メモリ
if [ -f "$RESULTS_DIR/spring_idle.csv" ]; then
    SPRING_MAX_RSS=$(tail -n +2 "$RESULTS_DIR/spring_idle.csv" | cut -d, -f2 | sort -n | tail -1)
    SPRING_AVG_RSS=$(tail -n +2 "$RESULTS_DIR/spring_idle.csv" | cut -d, -f2 | awk '{sum+=$1; count++} END {if(count>0) print int(sum/count)}')
    echo "Spring Boot JVM Max RSS: ${SPRING_MAX_RSS} KB ($(echo "scale=2; $SPRING_MAX_RSS / 1024" | bc) MB)"
    echo "Spring Boot JVM Avg RSS: ${SPRING_AVG_RSS} KB ($(echo "scale=2; $SPRING_AVG_RSS / 1024" | bc) MB)"
fi

echo ""
echo "-----------------------------------------"
echo "CPU Usage (Idle)"
echo "-----------------------------------------"

# Quarkus Native CPU
if [ -f "$RESULTS_DIR/quarkus-native_idle.csv" ]; then
    QUARKUS_NATIVE_MAX_CPU=$(tail -n +2 "$RESULTS_DIR/quarkus-native_idle.csv" | cut -d, -f3 | sort -n | tail -1)
    QUARKUS_NATIVE_AVG_CPU=$(tail -n +2 "$RESULTS_DIR/quarkus-native_idle.csv" | cut -d, -f3 | awk '{sum+=$1; count++} END {if(count>0) printf "%.2f", sum/count}')
    echo "Quarkus Native Max CPU: ${QUARKUS_NATIVE_MAX_CPU}%"
    echo "Quarkus Native Avg CPU: ${QUARKUS_NATIVE_AVG_CPU}%"
fi

# Quarkus JVM CPU
if [ -f "$RESULTS_DIR/quarkus_idle.csv" ]; then
    QUARKUS_JVM_MAX_CPU=$(tail -n +2 "$RESULTS_DIR/quarkus_idle.csv" | cut -d, -f3 | sort -n | tail -1)
    QUARKUS_JVM_AVG_CPU=$(tail -n +2 "$RESULTS_DIR/quarkus_idle.csv" | cut -d, -f3 | awk '{sum+=$1; count++} END {if(count>0) printf "%.2f", sum/count}')
    echo "Quarkus JVM Max CPU: ${QUARKUS_JVM_MAX_CPU}%"
    echo "Quarkus JVM Avg CPU: ${QUARKUS_JVM_AVG_CPU}%"
fi

# Spring CPU
if [ -f "$RESULTS_DIR/spring_idle.csv" ]; then
    SPRING_MAX_CPU=$(tail -n +2 "$RESULTS_DIR/spring_idle.csv" | cut -d, -f3 | sort -n | tail -1)
    SPRING_AVG_CPU=$(tail -n +2 "$RESULTS_DIR/spring_idle.csv" | cut -d, -f3 | awk '{sum+=$1; count++} END {if(count>0) printf "%.2f", sum/count}')
    echo "Spring Boot JVM Max CPU: ${SPRING_MAX_CPU}%"
    echo "Spring Boot JVM Avg CPU: ${SPRING_AVG_CPU}%"
fi

echo ""
echo "========================================="
echo ""
echo "Summary Comparison:"
echo ""

# 起動時間の比較（全て存在する場合）
if [ -n "$QUARKUS_NATIVE_READY" ] && [ -n "$QUARKUS_JVM_READY" ] && [ -n "$SPRING_READY" ]; then
    echo "Startup Time Comparison:"
    echo "  Quarkus Native: ${QUARKUS_NATIVE_READY}ms (1.0x baseline)"

    NATIVE_TO_JVM=$(echo "scale=1; $QUARKUS_JVM_READY / $QUARKUS_NATIVE_READY" | bc)
    echo "  Quarkus JVM:    ${QUARKUS_JVM_READY}ms (${NATIVE_TO_JVM}x slower than Native)"

    NATIVE_TO_SPRING=$(echo "scale=1; $SPRING_READY / $QUARKUS_NATIVE_READY" | bc)
    echo "  Spring JVM:     ${SPRING_READY}ms (${NATIVE_TO_SPRING}x slower than Native)"
    echo ""
fi

# メモリの比較
if [ -n "$QUARKUS_NATIVE_AVG_RSS" ] && [ -n "$QUARKUS_JVM_AVG_RSS" ] && [ -n "$SPRING_AVG_RSS" ]; then
    echo "Memory Usage Comparison (Average):"
    NATIVE_MB=$(echo "scale=2; $QUARKUS_NATIVE_AVG_RSS / 1024" | bc)
    JVM_MB=$(echo "scale=2; $QUARKUS_JVM_AVG_RSS / 1024" | bc)
    SPRING_MB=$(echo "scale=2; $SPRING_AVG_RSS / 1024" | bc)

    echo "  Quarkus Native: ${NATIVE_MB} MB"
    echo "  Quarkus JVM:    ${JVM_MB} MB"
    echo "  Spring JVM:     ${SPRING_MB} MB"
    echo ""

    # 削減率を正確に計算（scale=10で高精度計算してから丸める）
    SAVINGS_JVM=$(echo "scale=10; ($QUARKUS_JVM_AVG_RSS - $QUARKUS_NATIVE_AVG_RSS) / $QUARKUS_JVM_AVG_RSS * 100" | bc | awk '{printf "%.1f", $1}')
    SAVINGS_SPRING=$(echo "scale=10; ($SPRING_AVG_RSS - $QUARKUS_NATIVE_AVG_RSS) / $SPRING_AVG_RSS * 100" | bc | awk '{printf "%.1f", $1}')

    # メモリ比率を計算
    RATIO_JVM=$(echo "scale=10; $QUARKUS_JVM_AVG_RSS / $QUARKUS_NATIVE_AVG_RSS" | bc | awk '{printf "%.1f", $1}')
    RATIO_SPRING=$(echo "scale=10; $SPRING_AVG_RSS / $QUARKUS_NATIVE_AVG_RSS" | bc | awk '{printf "%.1f", $1}')

    echo "Memory Savings:"
    echo "  Native saves ${SAVINGS_JVM}% vs Quarkus JVM (${RATIO_JVM}x less memory)"
    echo "  Native saves ${SAVINGS_SPRING}% vs Spring JVM (${RATIO_SPRING}x less memory)"
fi

echo ""
echo "========================================="
