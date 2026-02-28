#!/bin/bash

# ========================================
# Spring Boot JVM API Test Script
# OpenShift Serverless Deployment
# ========================================

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get service URL from argument or OpenShift
if [ -n "$1" ]; then
    SERVICE_URL="$1"
else
    # Try to get URL from OpenShift
    SERVICE_URL=$(oc get ksvc spring-todo-jvm -n demo-serverless -o jsonpath='{.status.url}' 2>/dev/null)

    if [ -z "$SERVICE_URL" ]; then
        echo -e "${RED}Error: Could not get service URL${NC}"
        echo "Usage: $0 [SERVICE_URL]"
        echo "Example: $0 https://spring-todo-jvm-demo-serverless.apps.cluster-xxxxx.opentlc.com"
        exit 1
    fi
fi

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}  Spring Boot JVM API Test${NC}"
echo -e "${BLUE}  OpenShift Serverless${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""
echo -e "${YELLOW}Service URL:${NC} $SERVICE_URL"
echo ""

# Test counter
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_pattern="$3"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -e "${YELLOW}Test $TOTAL_TESTS: $test_name${NC}"

    # Execute command and capture output
    output=$(eval "$test_command" 2>&1)
    exit_code=$?

    # Check result
    if [ $exit_code -eq 0 ] && [[ -z "$expected_pattern" || "$output" =~ $expected_pattern ]]; then
        echo -e "${GREEN}✓ PASSED${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        if command -v jq &> /dev/null && [[ "$output" =~ ^\{ || "$output" =~ ^\[ ]]; then
            echo "$output" | jq . 2>/dev/null || echo "$output"
        else
            echo "$output"
        fi
    else
        echo -e "${RED}✗ FAILED${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        echo "Output: $output"
        echo "Exit code: $exit_code"
    fi
    echo ""
}

# Test 1: Health Check - Readiness
run_test "Health Check (Readiness)" \
    "curl -s $SERVICE_URL/actuator/health/readiness" \
    '"status":"UP"'

# Test 2: Health Check - Liveness
run_test "Health Check (Liveness)" \
    "curl -s $SERVICE_URL/actuator/health/liveness" \
    '"status":"UP"'

# Test 3: Actuator Endpoints
run_test "Actuator Endpoints List" \
    "curl -s $SERVICE_URL/actuator" \
    '"_links"'

# Test 4: Get all todos (should be empty initially)
run_test "Get all todos (empty list)" \
    "curl -s $SERVICE_URL/api/todos" \
    '^\[\]$'

# Test 5: Create a new todo
echo -e "${YELLOW}Test 5: Create a new todo${NC}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))
CREATE_RESPONSE=$(curl -s -X POST $SERVICE_URL/api/todos \
  -H 'Content-Type: application/json' \
  -d '{"title":"Test from OpenShift","description":"Spring Boot JVM on Serverless"}')

if echo "$CREATE_RESPONSE" | grep -q '"id"' && echo "$CREATE_RESPONSE" | grep -q '"title":"Test from OpenShift"'; then
    echo -e "${GREEN}✓ PASSED${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    TODO_ID=$(echo "$CREATE_RESPONSE" | grep -o '"id":[0-9]*' | grep -o '[0-9]*')
    echo "Created TODO ID: $TODO_ID"
    if command -v jq &> /dev/null; then
        echo "$CREATE_RESPONSE" | jq .
    else
        echo "$CREATE_RESPONSE"
    fi
else
    echo -e "${RED}✗ FAILED${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
    echo "Response: $CREATE_RESPONSE"
    TODO_ID=1
fi
echo ""

# Test 6: Get all todos (should have 1 item)
run_test "Get all todos (1 item)" \
    "curl -s $SERVICE_URL/api/todos" \
    '"id":'

# Test 7: Get specific todo
run_test "Get specific todo (ID=$TODO_ID)" \
    "curl -s $SERVICE_URL/api/todos/$TODO_ID" \
    '"title":"Test from OpenShift"'

# Test 8: Update todo
run_test "Update todo (ID=$TODO_ID)" \
    "curl -s -X PUT $SERVICE_URL/api/todos/$TODO_ID -H 'Content-Type: application/json' -d '{\"title\":\"Updated Title\",\"description\":\"Updated Description\",\"completed\":true}'" \
    '"completed":true'

# Test 9: Verify update
run_test "Verify updated todo" \
    "curl -s $SERVICE_URL/api/todos/$TODO_ID" \
    '"title":"Updated Title"'

# Test 10: Create another todo
echo -e "${YELLOW}Test 10: Create second todo${NC}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))
CREATE_RESPONSE2=$(curl -s -X POST $SERVICE_URL/api/todos \
  -H 'Content-Type: application/json' \
  -d '{"title":"Second Todo","description":"Another test item"}')

if echo "$CREATE_RESPONSE2" | grep -q '"id"'; then
    echo -e "${GREEN}✓ PASSED${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    TODO_ID2=$(echo "$CREATE_RESPONSE2" | grep -o '"id":[0-9]*' | grep -o '[0-9]*')
    echo "Created TODO ID: $TODO_ID2"
    if command -v jq &> /dev/null; then
        echo "$CREATE_RESPONSE2" | jq .
    else
        echo "$CREATE_RESPONSE2"
    fi
else
    echo -e "${RED}✗ FAILED${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
    echo "Response: $CREATE_RESPONSE2"
    TODO_ID2=2
fi
echo ""

# Test 11: Get all todos (should have 2 items)
run_test "Get all todos (2 items)" \
    "curl -s $SERVICE_URL/api/todos" \
    '\[.*,.*\]'

# Test 12: Delete first todo
run_test "Delete todo (ID=$TODO_ID)" \
    "curl -s -X DELETE $SERVICE_URL/api/todos/$TODO_ID" \
    ''

# Test 13: Verify deletion
echo -e "${YELLOW}Test 13: Verify todo was deleted${NC}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))
DELETE_CHECK=$(curl -s -o /dev/null -w "%{http_code}" $SERVICE_URL/api/todos/$TODO_ID)

if [ "$DELETE_CHECK" = "404" ]; then
    echo -e "${GREEN}✓ PASSED${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    echo "HTTP Status: 404 (Not Found)"
else
    echo -e "${RED}✗ FAILED${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
    echo "HTTP Status: $DELETE_CHECK (expected 404)"
fi
echo ""

# Test 14: Delete second todo
run_test "Delete second todo (ID=$TODO_ID2)" \
    "curl -s -X DELETE $SERVICE_URL/api/todos/$TODO_ID2" \
    ''

# Test 15: Get all todos (should be empty again)
run_test "Get all todos (empty after cleanup)" \
    "curl -s $SERVICE_URL/api/todos" \
    '^\[\]$'

# Test 16: Test validation - missing title
echo -e "${YELLOW}Test 16: Validation - missing title${NC}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))
VALIDATION_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST $SERVICE_URL/api/todos \
  -H 'Content-Type: application/json' \
  -d '{"description":"No title"}')

HTTP_CODE=$(echo "$VALIDATION_RESPONSE" | tail -1)
RESPONSE_BODY=$(echo "$VALIDATION_RESPONSE" | head -n -1)

if [ "$HTTP_CODE" = "400" ] || echo "$RESPONSE_BODY" | grep -qi "error\|invalid\|required"; then
    echo -e "${GREEN}✓ PASSED${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    echo "HTTP Status: $HTTP_CODE"
    echo "Response indicates validation error"
else
    echo -e "${RED}✗ FAILED${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
    echo "HTTP Status: $HTTP_CODE"
    echo "Response: $RESPONSE_BODY"
fi
echo ""

# Test 17: Test non-existent ID
echo -e "${YELLOW}Test 17: Get non-existent todo (404 expected)${NC}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))
NOT_FOUND_CODE=$(curl -s -o /dev/null -w "%{http_code}" $SERVICE_URL/api/todos/999)

if [ "$NOT_FOUND_CODE" = "404" ]; then
    echo -e "${GREEN}✓ PASSED${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    echo "HTTP Status: 404 (Not Found)"
else
    echo -e "${RED}✗ FAILED${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
    echo "HTTP Status: $NOT_FOUND_CODE (expected 404)"
fi
echo ""

# Test 18: Metrics endpoint
run_test "Actuator Metrics" \
    "curl -s $SERVICE_URL/actuator/metrics" \
    '"names":\['

# Test 19: JVM Memory Metrics
run_test "JVM Memory Metrics" \
    "curl -s $SERVICE_URL/actuator/metrics/jvm.memory.used" \
    '"measurements":'

# Summary
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}  Test Summary${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""
echo -e "Total Tests:  ${YELLOW}$TOTAL_TESTS${NC}"
echo -e "Passed:       ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed:       ${RED}$FAILED_TESTS${NC}"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    echo ""
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC}"
    echo ""
    exit 1
fi
