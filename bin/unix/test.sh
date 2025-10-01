#!/bin/bash

# Enhanced test script for messaging service endpoints
# This script tests the local messaging service with comprehensive field validation
# Usage: ./test.sh [test_number]
#   test_number: Optional parameter to run a specific test (1-20)

set -e

# Parse command line arguments
SPECIFIC_TEST=""
if [ $# -eq 1 ]; then
    SPECIFIC_TEST="$1"
    # Validate that the parameter is a number between 1-21
    if ! [[ "$SPECIFIC_TEST" =~ ^[0-9]+$ ]] || [ "$SPECIFIC_TEST" -lt 1 ] || [ "$SPECIFIC_TEST" -gt 21 ]; then
        echo "Error: Test number must be between 1 and 21"
        echo "Usage: $0 [test_number]"
        exit 1
    fi
fi

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
    local should_create_message="${4:-false}"
    local should_create_conversation="${5:-false}"
    
    TEST_COUNT=$((TEST_COUNT + 1))
    
    # Skip this test if we're running a specific test and this isn't it
    if [ -n "$SPECIFIC_TEST" ] && [ "$TEST_COUNT" -ne "$SPECIFIC_TEST" ]; then
        return 0
    fi
    
    echo -e "${BLUE}Test $TEST_COUNT: $test_name${NC}"
    
    # Get current message count before test
    local initial_count=$(get_message_count)
    local initial_conversation_count=$(get_conversation_count)
    
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
        
        # If this test should create a message and was successful, verify database
        local message_passed=false
        local conversation_passed=false
        if [ "$should_create_message" = "true" ] && [ "$expected_status" = "200" ]; then
            local expected_count=$((initial_count + 1))
            if verify_message_count "$expected_count"; then
                message_passed=true
            else
                message_passed=false
            fi
        else
            message_passed=true
        fi

        if [ "$should_create_conversation" = "true" ] && [ "$expected_status" = "200" ]; then
            local expected_count=$((initial_conversation_count + 1))
            if verify_conversation_count "$expected_count"; then
                conversation_passed=true
            else
                conversation_passed=false
            fi
        else
            conversation_passed=true
        fi

        if [ "$message_passed" = "true" ] && [ "$conversation_passed" = "true" ]; then
            PASSED_COUNT=$((PASSED_COUNT + 1))
        else
            FAILED_COUNT=$((FAILED_COUNT + 1))
        fi
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

# Function to clear the database
clear_database() {
    echo -e "${YELLOW}🗑️  Clearing database...${NC}"
    
    # Clear messages table
    docker exec messaging-service-db psql -U messaging_user -d messaging_service -c "DELETE FROM messages;" >/dev/null 2>&1
    
    # Clear conversations table
    docker exec messaging-service-db psql -U messaging_user -d messaging_service -c "DELETE FROM conversations;" >/dev/null 2>&1
    
    # Reset sequences
    docker exec messaging-service-db psql -U messaging_user -d messaging_service -c "ALTER SEQUENCE conversations_id_seq RESTART WITH 1;" >/dev/null 2>&1
    docker exec messaging-service-db psql -U messaging_user -d messaging_service -c "ALTER SEQUENCE messages_id_seq RESTART WITH 1;" >/dev/null 2>&1
    
    echo -e "${GREEN}✅ Database cleared${NC}"
    echo
}

# Function to get message count from database
get_message_count() {
    docker exec messaging-service-db psql -U messaging_user -d messaging_service -t -c "SELECT COUNT(*) FROM messages;" 2>/dev/null | tr -d ' \n'
}

# Function to get conversation count from database
get_conversation_count() {
    docker exec messaging-service-db psql -U messaging_user -d messaging_service -t -c "SELECT COUNT(*) FROM conversations;" 2>/dev/null | tr -d ' \n'
}

# Function to verify message count increment
verify_message_count() {
    local expected_count="$1"
    local actual_count=$(get_message_count)
    
    if [ "$actual_count" = "$expected_count" ]; then
        echo -e "${GREEN}✅ Database verification: $actual_count messages (expected: $expected_count)${NC}"
        return 0
    else
        echo -e "${RED}❌ Database verification failed: $actual_count messages (expected: $expected_count)${NC}"
        return 1
    fi
}

verify_conversation_count() {
    local expected_count="$1"
    local actual_count=$(get_conversation_count)
    
    if [ "$actual_count" = "$expected_count" ]; then
        echo -e "${GREEN}✅ Database verification: $actual_count conversations (expected: $expected_count)${NC}"
        return 0
    else
        echo -e "${RED}❌ Database verification failed: $actual_count conversations (expected: $expected_count)${NC}"
        return 1
    fi
}

echo -e "${PURPLE}=== Enhanced Messaging Service Test Suite ===${NC}"
echo -e "${PURPLE}Base URL: $BASE_URL${NC}"
if [ -n "$SPECIFIC_TEST" ]; then
    echo -e "${PURPLE}Running specific test: $SPECIFIC_TEST${NC}"
fi
echo

# Check if service is running
check_service

# Clear database before running tests
clear_database

echo -e "${CYAN}📋 Running Comprehensive Field Validation Tests${NC}"
echo

# === VALID TESTS ===
if [ -z "$SPECIFIC_TEST" ] || [ "$SPECIFIC_TEST" -le 8 ]; then
    echo -e "${GREEN}✅ VALID TESTS${NC}"
    echo -e "${GREEN}==============${NC}"
fi

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
  -w '\nStatus: %{http_code}'" "true" "true"

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
  -w '\nStatus: %{http_code}'" "true" "false"

# Test 3: Valid Email send
run_test "Valid Email send" "200" "curl -X POST '$BASE_URL/api/messages/email' \
  -H '$CONTENT_TYPE' \
  -d '{
    \"from\": \"user@usehatchapp.com\",
    \"to\": \"contact@gmail.com\",
    \"type\": \"email\",
    \"body\": \"Hello! This is a test email message with <b>HTML</b> formatting.\",
    \"attachments\": [\"https://example.com/document.pdf\"],
    \"timestamp\": \"2024-11-01T14:00:00Z\"
  }' \
  -w '\nStatus: %{http_code}'" "true" "true"

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
  -w '\nStatus: %{http_code}'" "true" "false"

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
  -w '\nStatus: %{http_code}'" "true" "false"

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
  -w '\nStatus: %{http_code}'" "true" "false"

# Test 7: Get conversations
run_test "Get conversations" "200" "curl -X GET '$BASE_URL/api/conversations' \
  -H '$CONTENT_TYPE' \
  -w '\nStatus: %{http_code}'"

# Test 8: Get messages for conversation
run_test "Get messages for conversation" "200" "curl -X GET '$BASE_URL/api/conversations/1/messages' \
  -H '$CONTENT_TYPE' \
  -w '\nStatus: %{http_code}'"

echo
if [ -z "$SPECIFIC_TEST" ] || [ "$SPECIFIC_TEST" -ge 9 ]; then
    echo -e "${RED}❌ INVALID FIELD TESTS${NC}"
    echo -e "${RED}=====================${NC}"
fi

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
run_test "Get messages for non-existent conversation" "404" "curl -X GET '$BASE_URL/api/conversations/99999/messages' \
  -H '$CONTENT_TYPE' \
  -w '\nStatus: %{http_code}'"

# Test 21: Concurrency test - 10 simultaneous requests
run_concurrency_test() {
    local test_name="Concurrency test - 10 simultaneous requests"
    TEST_COUNT=$((TEST_COUNT + 1))
    
    # Skip this test if we're running a specific test and this isn't it
    if [ -n "$SPECIFIC_TEST" ] && [ "$TEST_COUNT" -ne "$SPECIFIC_TEST" ]; then
        return 0
    fi
    
    echo -e "${BLUE}Test $TEST_COUNT: $test_name${NC}"
    
    # Create temporary files for storing results
    local temp_dir=$(mktemp -d)
    local results_file="$temp_dir/results.txt"
    local pids_file="$temp_dir/pids.txt"
    
    echo "Starting 10 concurrent requests..."
    local start_time=$(date +%s.%N)
    
    # Launch 10 concurrent requests
    for i in {1..10}; do
        (
            local response=$(curl -X POST "$BASE_URL/api/messages/sms" \
                -H "$CONTENT_TYPE" \
                -d "{
                    \"from\": \"+1201666123$i\",
                    \"to\": \"+1804555123$i\",
                    \"type\": \"sms\",
                    \"body\": \"Concurrent test message $i\",
                    \"attachments\": null,
                    \"timestamp\": \"2024-11-01T14:00:00Z\"
                }" \
                -w "\nStatus: %{http_code}" \
                -s 2>/dev/null)
            
            local http_status=$(echo "$response" | tail -n 1 | grep -o '[0-9]\{3\}' || echo "000")
            echo "Request $i: Status $http_status" >> "$results_file"
        ) &
        echo $! >> "$pids_file"
    done
    
    # Wait for all background processes to complete
    while read -r pid; do
        wait "$pid"
    done < "$pids_file"
    
    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $start_time" | bc -l)
    
    # Display results
    echo "Concurrent execution results:"
    cat "$results_file"
    
    # Count successful requests
    local success_count=$(grep -c "Status 200" "$results_file" 2>/dev/null || echo "0")
    local total_requests=10
    
    echo -e "${CYAN}Concurrent execution time: ${duration}s${NC}"
    echo -e "${CYAN}Successful requests: $success_count/$total_requests${NC}"
    
    # Clean up temporary files
    rm -rf "$temp_dir"
    
    # Test passes if all 10 requests completed successfully
    if [ "$success_count" -eq "$total_requests" ]; then
        echo -e "${GREEN}✅ PASS${NC} - All 10 concurrent requests completed successfully"
        PASSED_COUNT=$((PASSED_COUNT + 1))
    else
        echo -e "${RED}❌ FAIL${NC} - Only $success_count out of $total_requests requests succeeded"
        FAILED_COUNT=$((FAILED_COUNT + 1))
    fi
    echo
}

run_concurrency_test

echo
echo -e "${PURPLE}=== TEST RESULTS SUMMARY ===${NC}"
if [ -n "$SPECIFIC_TEST" ]; then
    echo -e "${PURPLE}Running specific test: $SPECIFIC_TEST${NC}"
    echo -e "${GREEN}Passed: $PASSED_COUNT${NC}"
    echo -e "${RED}Failed: $FAILED_COUNT${NC}"
else
    echo -e "${PURPLE}Total Tests: $TEST_COUNT${NC}"
    echo -e "${GREEN}Passed: $PASSED_COUNT${NC}"
    echo -e "${RED}Failed: $FAILED_COUNT${NC}"
fi
echo

# Overall result
if [ $FAILED_COUNT -eq 0 ]; then
    if [ -n "$SPECIFIC_TEST" ]; then
        echo -e "${GREEN}✅ TEST $SPECIFIC_TEST PASSED! 🎉${NC}"
    else
        echo -e "${GREEN}✅ ALL TESTS PASSED! 🎉${NC}"
    fi
    exit 0
else
    if [ -n "$SPECIFIC_TEST" ]; then
        echo -e "${RED}❌ TEST $SPECIFIC_TEST FAILED! 😞${NC}"
    else
        echo -e "${RED}❌ SOME TESTS FAILED! 😞${NC}"
    fi
    exit 1
fi 