#!/bin/bash

# Quick Smoke Test for Todo API
# Usage: ./smoke_test.sh [port]
#   Default: 8081 (Quarkus)
#   Spring Boot: ./smoke_test.sh 8082

PORT=${1:-8081}
BASE_URL="http://localhost:$PORT"
API_URL="$BASE_URL/api/todos"

echo "========================================="
echo "  Quick Smoke Test"
echo "  Testing: $BASE_URL"
echo "========================================="
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Check if server is running
echo -n "1. Health check... "
if curl -s -f "$BASE_URL/q/health/ready" > /dev/null 2>&1 || \
   curl -s -f "$BASE_URL/actuator/health" > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗ Server not running${NC}"
    exit 1
fi

# Create a todo
echo -n "2. Create todo... "
CREATE_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_URL" \
    -H "Content-Type: application/json" \
    -d '{"title":"Smoke test","description":"Quick test"}')
CREATE_CODE=$(echo "$CREATE_RESPONSE" | tail -n1)
CREATE_BODY=$(echo "$CREATE_RESPONSE" | sed '$d')

if [ "$CREATE_CODE" = "201" ]; then
    TODO_ID=$(echo "$CREATE_BODY" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
    echo -e "${GREEN}✓${NC} (ID: ${TODO_ID:0:8}...)"
else
    echo -e "${RED}✗ (HTTP $CREATE_CODE)${NC}"
    exit 1
fi

# Get all todos
echo -n "3. List todos... "
LIST_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL")
if [ "$LIST_CODE" = "200" ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗ (HTTP $LIST_CODE)${NC}"
    exit 1
fi

# Get by ID
echo -n "4. Get by ID... "
GET_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL/$TODO_ID")
if [ "$GET_CODE" = "200" ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗ (HTTP $GET_CODE)${NC}"
    exit 1
fi

# Update
echo -n "5. Update todo... "
UPDATE_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X PATCH "$API_URL/$TODO_ID" \
    -H "Content-Type: application/json" \
    -d '{"completed":true}')
if [ "$UPDATE_CODE" = "200" ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗ (HTTP $UPDATE_CODE)${NC}"
    exit 1
fi

# Delete
echo -n "6. Delete todo... "
DELETE_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "$API_URL/$TODO_ID")
if [ "$DELETE_CODE" = "204" ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗ (HTTP $DELETE_CODE)${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}All smoke tests passed! ✓${NC}"
echo ""
