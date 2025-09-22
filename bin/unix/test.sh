#!/bin/bash

# Enhanced test script for messaging service endpoints
# This script tests the local messaging service with comprehensive field validation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test configuration
BASE_URL="http://localhost:8080"
CONTENT_TYPE="Content-Type: application/json"
TEST_COUNT=0
PASSED_COUNT=0
FAILED_COUNT=0

# Function to run a test and check the result
run_test() {
    local test_name="$1"
    local expected_status="$2"
    local curl_command="$3"
    
    TEST_COUNT=$((TEST_COUNT + 1))
    
    echo -e "${BLUE}Test $TEST_COUNT: $test_name${NC}"
    
    # Run the curl command and capture the HTTP status code
    local response
    local http_status
    
    response=$(eval "$curl_command" 2>/dev/null)
    http_status=$(echo "$response" | tail -n 1 | grep -o '[0-9]\{3\}' || echo "000")
    
    # Display the response (without the status line)
    echo "$response" | sed '$d'
    
    # Check if the status code matches expected
    if [ "$http_status" = "$expected_status" ]; then
        echo -e "${GREEN}✅ PASS${NC} - Expected status $expected_status, got $http_status"
        PASSED_COUNT=$((PASSED_COUNT + 1))
    else
        echo -e "${RED}❌ FAIL${NC} - Expected status $expected_status, got $http_status"
        FAILED_COUNT=$((FAILED_COUNT + 1))
    fi
    echo
}

# Function to check if service is running
check_service() {
    echo -e "${YELLOW}🔍 Checking if messaging service is running...${NC}"
    
    if curl -s -f "$BASE_URL/health" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Service is running${NC}"
        echo
    else
        echo -e "${RED}❌ Service is not running or not accessible${NC}"
        echo -e "${YELLOW}💡 Start the service with: ./bin/start${NC}"
        exit 1
    fi
}

echo -e "${PURPLE}=== Enhanced Messaging Service Test Suite ===${NC}"
echo -e "${PURPLE}Base URL: $BASE_URL${NC}"
echo

# Check if service is running
check_service

echo -e "${CYAN}📋 Running Comprehensive Field Validation Tests${NC}"
echo

# === VALID TESTS ===
echo -e "${GREEN}✅ VALID TESTS${NC}"
echo -e "${GREEN}==============${NC}"

# Test 1: Valid SMS send
run_test "Valid SMS send" "200" "curl -X POST '$BASE_URL/api/messages/sms' \
  -H '$CONTENT_TYPE' \
  -d '{
    \"from\": \"+12016661234\",
    \"to\": \"+18045551234\",
    \"type\": \"sms\",
    \"body\": \"Hello! This is a test SMS message.\",
    \"attachments\": null,
    \"timestamp\": \"2024-11-01T14:00:00Z\"
  }' \
  -w '\nStatus: %{http_code}'"

# Test 2: Valid MMS send
run_test "Valid MMS send" "200" "curl -X POST '$BASE_URL/api/messages/sms' \
  -H '$CONTENT_TYPE' \
  -d '{
    \"from\": \"+12016661234\",
    \"to\": \"+18045551234\",
    \"type\": \"mms\",
    \"body\": \"Hello! This is a test MMS message with attachment.\",
    \"attachments\": [\"https://example.com/image.jpg\"],
    \"timestamp\": \"2024-11-01T14:00:00Z\"
  }' \
  -w '\nStatus: %{http_code}'"

# Test 3: Valid Email send
run_test "Valid Email send" "200" "curl -X POST '$BASE_URL/api/messages/email' \
  -H '$CONTENT_TYPE' \
  -d '{
    \"from\": \"user@usehatchapp.com\",
    \"to\": \"contact@gmail.com\",
    \"body\": \"Hello! This is a test email message with <b>HTML</b> formatting.\",
    \"attachments\": [\"https://example.com/document.pdf\"],
    \"timestamp\": \"2024-11-01T14:00:00Z\"
  }' \
  -w '\nStatus: %{http_code}'"

# Test 4: Valid incoming SMS webhook
run_test "Valid incoming SMS webhook" "200" "curl -X POST '$BASE_URL/api/webhooks/sms' \
  -H '$CONTENT_TYPE' \
  -d '{
    \"from\": \"+18045551234\",
    \"to\": \"+12016661234\",
    \"type\": \"sms\",
    \"messaging_provider_id\": \"message-1\",
    \"body\": \"This is an incoming SMS message\",
    \"attachments\": null,
    \"timestamp\": \"2024-11-01T14:00:00Z\"
  }' \
  -w '\nStatus: %{http_code}'"

# Test 5: Valid incoming MMS webhook
run_test "Valid incoming MMS webhook" "200" "curl -X POST '$BASE_URL/api/webhooks/sms' \
  -H '$CONTENT_TYPE' \
  -d '{
    \"from\": \"+18045551234\",
    \"to\": \"+12016661234\",
    \"type\": \"mms\",
    \"messaging_provider_id\": \"message-2\",
    \"body\": \"This is an incoming MMS message\",
    \"attachments\": [\"https://example.com/received-image.jpg\"],
    \"timestamp\": \"2024-11-01T14:00:00Z\"
  }' \
  -w '\nStatus: %{http_code}'"

# Test 6: Valid incoming Email webhook
run_test "Valid incoming Email webhook" "200" "curl -X POST '$BASE_URL/api/webhooks/email' \
  -H '$CONTENT_TYPE' \
  -d '{
    \"from\": \"contact@gmail.com\",
    \"to\": \"user@usehatchapp.com\",
    \"xillio_id\": \"message-3\",
    \"body\": \"<html><body>This is an incoming email with <b>HTML</b> content</body></html>\",
    \"attachments\": [\"https://example.com/received-document.pdf\"],
    \"timestamp\": \"2024-11-01T14:00:00Z\"
  }' \
  -w '\nStatus: %{http_code}'"

# Test 7: Get conversations
run_test "Get conversations" "200" "curl -X GET '$BASE_URL/api/conversations' \
  -H '$CONTENT_TYPE' \
  -w '\nStatus: %{http_code}'"

# Test 8: Get messages for conversation
run_test "Get messages for conversation" "200" "curl -X GET '$BASE_URL/api/conversations/1/messages' \
  -H '$CONTENT_TYPE' \
  -w '\nStatus: %{http_code}'"

echo
echo -e "${RED}❌ INVALID FIELD TESTS${NC}"
echo -e "${RED}=====================${NC}"

# === INVALID FIELD TESTS ===

# Test 9: Missing required field - from
run_test "SMS webhook missing 'from' field" "400" "curl -X POST '$BASE_URL/api/webhooks/sms' \
  -H '$CONTENT_TYPE' \
  -d '{
    \"to\": \"+12016661234\",
    \"type\": \"sms\",
    \"messaging_provider_id\": \"message-1\",
    \"body\": \"Missing from field\",
    \"timestamp\": \"2024-11-01T14:00:00Z\"
  }' \
  -w '\nStatus: %{http_code}'"

# Test 10: Missing required field - to
run_test "SMS webhook missing 'to' field" "400" "curl -X POST '$BASE_URL/api/webhooks/sms' \
  -H '$CONTENT_TYPE' \
  -d '{
    \"from\": \"+18045551234\",
    \"type\": \"sms\",
    \"messaging_provider_id\": \"message-1\",
    \"body\": \"Missing to field\",
    \"timestamp\": \"2024-11-01T14:00:00Z\"
  }' \
  -w '\nStatus: %{http_code}'"

# Test 11: Missing required field - type
run_test "SMS webhook missing 'type' field" "400" "curl -X POST '$BASE_URL/api/webhooks/sms' \
  -H '$CONTENT_TYPE' \
  -d '{
    \"from\": \"+18045551234\",
    \"to\": \"+12016661234\",
    \"messaging_provider_id\": \"message-1\",
    \"body\": \"Missing type field\",
    \"timestamp\": \"2024-11-01T14:00:00Z\"
  }' \
  -w '\nStatus: %{http_code}'"

# Test 12: Missing required field - messaging_provider_id
run_test "SMS webhook missing 'messaging_provider_id' field" "400" "curl -X POST '$BASE_URL/api/webhooks/sms' \
  -H '$CONTENT_TYPE' \
  -d '{
    \"from\": \"+18045551234\",
    \"to\": \"+12016661234\",
    \"type\": \"sms\",
    \"body\": \"Missing messaging_provider_id field\",
    \"timestamp\": \"2024-11-01T14:00:00Z\"
  }' \
  -w '\nStatus: %{http_code}'"

# Test 13: Missing required field - body
run_test "SMS webhook missing 'body' field" "400" "curl -X POST '$BASE_URL/api/webhooks/sms' \
  -H '$CONTENT_TYPE' \
  -d '{
    \"from\": \"+18045551234\",
    \"to\": \"+12016661234\",
    \"type\": \"sms\",
    \"messaging_provider_id\": \"message-1\",
    \"timestamp\": \"2024-11-01T14:00:00Z\"
  }' \
  -w '\nStatus: %{http_code}'"

# Test 14: Missing required field - timestamp
run_test "SMS webhook missing 'timestamp' field" "400" "curl -X POST '$BASE_URL/api/webhooks/sms' \
  -H '$CONTENT_TYPE' \
  -d '{
    \"from\": \"+18045551234\",
    \"to\": \"+12016661234\",
    \"type\": \"sms\",
    \"messaging_provider_id\": \"message-1\",
    \"body\": \"Missing timestamp field\"
  }' \
  -w '\nStatus: %{http_code}'"

# Test 15: Invalid message type
run_test "SMS webhook with invalid 'type' field" "400" "curl -X POST '$BASE_URL/api/webhooks/sms' \
  -H '$CONTENT_TYPE' \
  -d '{
    \"from\": \"+18045551234\",
    \"to\": \"+12016661234\",
    \"type\": \"invalid_type\",
    \"messaging_provider_id\": \"message-1\",
    \"body\": \"Invalid type field\",
    \"timestamp\": \"2024-11-01T14:00:00Z\"
  }' \
  -w '\nStatus: %{http_code}'"

# Test 16: Empty required fields
run_test "SMS webhook with empty required fields" "400" "curl -X POST '$BASE_URL/api/webhooks/sms' \
  -H '$CONTENT_TYPE' \
  -d '{
    \"from\": \"\",
    \"to\": \"\",
    \"type\": \"sms\",
    \"messaging_provider_id\": \"\",
    \"body\": \"\",
    \"timestamp\": \"\"
  }' \
  -w '\nStatus: %{http_code}'"

# Test 17: Email webhook missing xillio_id
run_test "Email webhook missing 'xillio_id' field" "400" "curl -X POST '$BASE_URL/api/webhooks/email' \
  -H '$CONTENT_TYPE' \
  -d '{
    \"from\": \"contact@gmail.com\",
    \"to\": \"user@usehatchapp.com\",
    \"body\": \"Missing xillio_id field\",
    \"timestamp\": \"2024-11-01T14:00:00Z\"
  }' \
  -w '\nStatus: %{http_code}'"

# Test 18: Invalid JSON format
run_test "Invalid JSON format" "500" "curl -X POST '$BASE_URL/api/webhooks/sms' \
  -H '$CONTENT_TYPE' \
  -d '{
    \"from\": \"+18045551234\",
    \"to\": \"+12016661234\",
    \"type\": \"sms\",
    \"messaging_provider_id\": \"message-1\",
    \"body\": \"Invalid JSON\",
    \"timestamp\": \"2024-11-01T14:00:00Z\"
    // Missing closing brace
  }' \
  -w '\nStatus: %{http_code}'"

# Test 19: Wrong endpoint for SMS
run_test "SMS data sent to email endpoint" "400" "curl -X POST '$BASE_URL/api/webhooks/email' \
  -H '$CONTENT_TYPE' \
  -d '{
    \"from\": \"+18045551234\",
    \"to\": \"+12016661234\",
    \"type\": \"sms\",
    \"messaging_provider_id\": \"message-1\",
    \"body\": \"SMS sent to email endpoint\",
    \"timestamp\": \"2024-11-01T14:00:00Z\"
  }' \
  -w '\nStatus: %{http_code}'"

# Test 20: Non-existent conversation ID
run_test "Get messages for non-existent conversation" "200" "curl -X GET '$BASE_URL/api/conversations/99999/messages' \
  -H '$CONTENT_TYPE' \
  -w '\nStatus: %{http_code}'"

echo
echo -e "${PURPLE}=== TEST RESULTS SUMMARY ===${NC}"
echo -e "${PURPLE}Total Tests: $TEST_COUNT${NC}"
echo -e "${GREEN}Passed: $PASSED_COUNT${NC}"
echo -e "${RED}Failed: $FAILED_COUNT${NC}"
echo

# Overall result
if [ $FAILED_COUNT -eq 0 ]; then
    echo -e "${GREEN}✅ ALL TESTS PASSED! 🎉${NC}"
    exit 0
else
    echo -e "${RED}❌ SOME TESTS FAILED! 😞${NC}"
    exit 1
fi 