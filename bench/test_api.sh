#!/bin/bash

# API Test Script for Todo Application
# Tests all CRUD operations
# Usage: ./test_api.sh [port]
#   Default port: 8081 (Quarkus)
#   Spring Boot: ./test_api.sh 8082

PORT=${1:-8081}
BASE_URL="http://localhost:$PORT"
API_URL="$BASE_URL/api/todos"

echo "========================================="
echo "  Todo API Test Suite"
echo "  Testing: $BASE_URL"
echo "========================================="
echo ""

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Helper function to check if server is running
check_server() {
    echo "Checking if server is running..."
    if curl -s -f "$BASE_URL/q/health/ready" > /dev/null 2>&1 || \
       curl -s -f "$BASE_URL/actuator/health" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Server is ready"
        echo ""
        return 0
    else
        echo -e "${RED}✗${NC} Server is not running on port $PORT"
        echo ""
        echo "Start the server first:"
        echo "  Quarkus Native: ./quarkus-todo/target/quarkus-todo-1.0.0-SNAPSHOT-runner"
        echo "  Quarkus JVM:    java -jar quarkus-todo/target/quarkus-app/quarkus-run.jar"
        echo "  Spring Boot:    java -jar spring-todo/target/spring-todo-0.0.1-SNAPSHOT.jar"
        exit 1
    fi
}

# Helper function to test endpoint
test_endpoint() {
    local test_name="$1"
    local method="$2"
    local url="$3"
    local data="$4"
    local expected_status="$5"

    echo "Test: $test_name"

    if [ -n "$data" ]; then
        response=$(curl -s -w "\n%{http_code}" -X "$method" "$url" \
            -H "Content-Type: application/json" \
            -d "$data")
    else
        response=$(curl -s -w "\n%{http_code}" -X "$method" "$url")
    fi

    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')

    if [ "$http_code" = "$expected_status" ]; then
        echo -e "${GREEN}✓${NC} Status: $http_code (expected $expected_status)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo "$body" | jq . 2>/dev/null || echo "$body"
        echo ""
        echo "$body"
        return 0
    else
        echo -e "${RED}✗${NC} Status: $http_code (expected $expected_status)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo "Response: $body"
        echo ""
        return 1
    fi
}

# Start tests
check_server

echo "========================================="
echo "  1. CREATE (POST)"
echo "========================================="
echo ""

TODO1=$(test_endpoint \
    "Create Todo 1" \
    "POST" \
    "$API_URL" \
    '{"title":"Buy groceries","description":"Milk, eggs, bread"}' \
    "201")

TODO1_ID=$(echo "$TODO1" | jq -r '.id // empty' 2>/dev/null)

TODO2=$(test_endpoint \
    "Create Todo 2" \
    "POST" \
    "$API_URL" \
    '{"title":"Write report","description":"Q4 performance report"}' \
    "201")

TODO2_ID=$(echo "$TODO2" | jq -r '.id // empty' 2>/dev/null)

TODO3=$(test_endpoint \
    "Create Todo 3 (completed)" \
    "POST" \
    "$API_URL" \
    '{"title":"Review code","description":"PR #123","completed":true}' \
    "201")

TODO3_ID=$(echo "$TODO3" | jq -r '.id // empty' 2>/dev/null)

echo "========================================="
echo "  2. READ (GET)"
echo "========================================="
echo ""

test_endpoint \
    "Get all todos" \
    "GET" \
    "$API_URL" \
    "" \
    "200"

if [ -n "$TODO1_ID" ]; then
    test_endpoint \
        "Get Todo 1 by ID" \
        "GET" \
        "$API_URL/$TODO1_ID" \
        "" \
        "200"
fi

echo "========================================="
echo "  3. UPDATE (PUT - Full Replace)"
echo "========================================="
echo ""

if [ -n "$TODO2_ID" ]; then
    test_endpoint \
        "Update Todo 2 (PUT)" \
        "PUT" \
        "$API_URL/$TODO2_ID" \
        '{"title":"Write Q4 report","description":"Updated: Q4 performance and metrics report","completed":false}' \
        "200"
fi

echo "========================================="
echo "  4. PARTIAL UPDATE (PATCH)"
echo "========================================="
echo ""

if [ -n "$TODO1_ID" ]; then
    test_endpoint \
        "Mark Todo 1 as completed (PATCH)" \
        "PATCH" \
        "$API_URL/$TODO1_ID" \
        '{"completed":true}' \
        "200"
fi

echo "========================================="
echo "  5. DELETE"
echo "========================================="
echo ""

if [ -n "$TODO3_ID" ]; then
    test_endpoint \
        "Delete Todo 3" \
        "DELETE" \
        "$API_URL/$TODO3_ID" \
        "" \
        "204"

    # Verify deletion
    echo "Verify Todo 3 is deleted"
    response=$(curl -s -w "\n%{http_code}" -X "GET" "$API_URL/$TODO3_ID")
    http_code=$(echo "$response" | tail -n1)

    if [ "$http_code" = "404" ]; then
        echo -e "${GREEN}✓${NC} Todo 3 is deleted (404 as expected)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} Todo 3 still exists (got $http_code, expected 404)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    echo ""
fi

echo "========================================="
echo "  6. VALIDATION TESTS"
echo "========================================="
echo ""

test_endpoint \
    "Invalid: Empty title" \
    "POST" \
    "$API_URL" \
    '{"title":"","description":"Should fail"}' \
    "400"

test_endpoint \
    "Invalid: Missing title" \
    "POST" \
    "$API_URL" \
    '{"description":"Should fail"}' \
    "400"

test_endpoint \
    "Invalid: Get non-existent todo" \
    "GET" \
    "$API_URL/00000000-0000-0000-0000-000000000000" \
    "" \
    "404"

echo "========================================="
echo "  Test Summary"
echo "========================================="
echo ""
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed! ✓${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed ✗${NC}"
    exit 1
fi
