#!/bin/bash

if [ $# -ne 3 ]; then
    echo "Usage: $0 <pid> <duration_seconds> <output_csv>"
    echo "Example: $0 12345 60 results/quarkus_idle.csv"
    exit 1
fi

PID=$1
DURATION=$2
OUTPUT_CSV=$3

if ! ps -p $PID > /dev/null 2>&1; then
    echo "Error: Process $PID is not running"
    exit 1
fi

mkdir -p "$(dirname "$OUTPUT_CSV")"

echo "timestamp,rss_kb,cpu_percent" > "$OUTPUT_CSV"
echo "Measuring PID $PID for ${DURATION}s..."

END_TIME=$(($(date +%s) + DURATION))

while [ $(date +%s) -lt $END_TIME ]; do
    TIMESTAMP=$(date +%s)

    # macOS と Linux で異なるコマンドを使う
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS: ps の出力形式が異なる
        RSS=$(ps -o rss= -p $PID 2>/dev/null | awk '{print $1}')
        CPU=$(ps -o %cpu= -p $PID 2>/dev/null | awk '{print $1}')
    else
        # Linux
        RSS=$(ps -o rss= -p $PID 2>/dev/null)
        CPU=$(ps -o %cpu= -p $PID 2>/dev/null)
    fi

    if [ -n "$RSS" ] && [ -n "$CPU" ]; then
        echo "$TIMESTAMP,$RSS,$CPU" >> "$OUTPUT_CSV"
    else
        echo "Warning: Could not get metrics for PID $PID"
        break
    fi

    sleep 1
done

echo "Measurement complete. Results saved to $OUTPUT_CSV"
