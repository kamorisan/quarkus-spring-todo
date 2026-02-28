#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 <base_url>"
    echo "Example: $0 http://localhost:8081"
    exit 1
fi

BASE_URL=$1
API_URL="$BASE_URL/api/todos"

echo "Running load test against $API_URL..."

# 初期データを投入
echo "Creating initial todos..."
for i in {1..10}; do
    curl -s -X POST "$API_URL" \
        -H "Content-Type: application/json" \
        -d "{\"title\": \"Test Todo $i\", \"description\": \"Load test data\", \"completed\": false}" \
        > /dev/null
done

echo "Initial data created"

# curlで簡易負荷テスト（30秒間）
echo "Starting load test (30 seconds)..."
END_TIME=$(($(date +%s) + 30))
REQUEST_COUNT=0

while [ $(date +%s) -lt $END_TIME ]; do
    curl -s "$API_URL?page=0&size=20" > /dev/null &
    REQUEST_COUNT=$((REQUEST_COUNT + 1))
    sleep 0.1
done

wait
echo "Load test complete. Sent $REQUEST_COUNT requests"
