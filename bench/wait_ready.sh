#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 <ready_url>"
    echo "Example: $0 http://localhost:8081/health/ready"
    exit 1
fi

READY_URL=$1
MAX_WAIT=120
INTERVAL=0.5

echo "Waiting for application to be ready at $READY_URL..."
START_TIME=$(date +%s.%N)

elapsed=0
while [ $(echo "$elapsed < $MAX_WAIT" | bc) -eq 1 ]; do
    if curl -sf "$READY_URL" > /dev/null 2>&1; then
        END_TIME=$(date +%s.%N)
        DURATION=$(echo "$END_TIME - $START_TIME" | bc)
        DURATION_MS=$(echo "$DURATION * 1000" | bc | cut -d. -f1)
        echo "Application ready in ${DURATION_MS}ms (${DURATION}s)"
        exit 0
    fi
    sleep $INTERVAL
    elapsed=$(echo "$(date +%s.%N) - $START_TIME" | bc)
done

echo "Timeout waiting for application to be ready"
exit 1
