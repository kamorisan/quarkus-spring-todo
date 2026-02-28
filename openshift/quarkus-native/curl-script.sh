#!/bin/bash

SERVICE_URL=https://quarkus-todo-native-demo-serverless.apps.cluster-5rxv7.5rxv7.sandbox2408.opentlc.com

echo "========================================="
echo "Testing Quarkus Native on OpenShift"
echo "========================================="
echo ""

echo "1. Health Check (Ready):"
curl -s $SERVICE_URL/q/health/ready | jq .
echo ""

echo "2. Get all todos (should be empty):"
curl -s $SERVICE_URL/api/todos | jq .
echo ""

echo "3. Create a todo:"
RESPONSE=$(curl -s -X POST $SERVICE_URL/api/todos \
  -H 'Content-Type: application/json' \
  -d '{"title":"Native Image Test","description":"Testing Quarkus Native on OpenShift"}')
echo $RESPONSE | jq .
TODO_ID=$(echo $RESPONSE | jq -r '.id')
echo "Created TODO ID: $TODO_ID"
echo ""

echo "4. Get all todos (should show 1 item):"
curl -s $SERVICE_URL/api/todos | jq .
echo ""

echo "5. Get specific todo (ID=$TODO_ID):"
curl -s $SERVICE_URL/api/todos/$TODO_ID | jq .
echo ""

echo "6. Update todo:"
curl -s -X PUT $SERVICE_URL/api/todos/$TODO_ID \
  -H 'Content-Type: application/json' \
  -d '{"title":"Updated Native Test","description":"Updated on OpenShift","completed":true}' | jq .
echo ""

echo "7. Delete todo:"
curl -s -X DELETE $SERVICE_URL/api/todos/$TODO_ID
echo ""

echo "8. Get all todos (should be empty again):"
curl -s $SERVICE_URL/api/todos | jq .
echo ""

echo "========================================="
echo "Test Complete!"
echo "========================================="
