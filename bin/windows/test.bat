@echo off
setlocal enabledelayedexpansion

REM Enhanced test script for messaging service endpoints (Windows version)
REM This script tests the local messaging service with comprehensive field validation
REM Usage: test.bat [test_number]
REM   test_number: Optional parameter to run a specific test (1-20)

REM Parse command line arguments
set "SPECIFIC_TEST="
if "%~1" neq "" (
    set "SPECIFIC_TEST=%~1"
    REM Basic validation that parameter is a number between 1-20
    echo %SPECIFIC_TEST% | findstr /r "^[0-9][0-9]*$" >nul
    if errorlevel 1 (
        echo Error: Test number must be between 1 and 20
        echo Usage: %~nx0 [test_number]
        exit /b 1
    )
    if %SPECIFIC_TEST% lss 1 (
        echo Error: Test number must be between 1 and 20
        echo Usage: %~nx0 [test_number]
        exit /b 1
    )
    if %SPECIFIC_TEST% gtr 20 (
        echo Error: Test number must be between 1 and 20
        echo Usage: %~nx0 [test_number]
        exit /b 1
    )
)

REM Colors are not easily supported in Windows batch, so we'll use text indicators
set "PASS_MARK=✅"
set "FAIL_MARK=❌"
set "INFO_MARK=ℹ️"

REM Test configuration
set "BASE_URL=http://localhost:8080"
set "CONTENT_TYPE=Content-Type: application/json"
set "TEST_COUNT=0"
set "PASSED_COUNT=0"
set "FAILED_COUNT=0"

REM Function to run a test and check the result
:run_test
set "test_name=%~1"
set "expected_status=%~2"
set "curl_command=%~3"

set /a TEST_COUNT+=1

REM Skip this test if we're running a specific test and this isn't it
if not "!SPECIFIC_TEST!"=="" (
    if not !TEST_COUNT!==!SPECIFIC_TEST! goto :eof
)

echo Test !TEST_COUNT!: !test_name!

REM Run the curl command and capture the HTTP status code
for /f "tokens=*" %%i in ('!curl_command! 2^>nul') do set "response=%%i"

REM Extract HTTP status code (last line should contain the status)
for /f "tokens=*" %%i in ('echo !response! ^| findstr /r "[0-9][0-9][0-9]"') do set "http_status=%%i"

REM Display the response (without the status line)
echo !response! | findstr /v /r "[0-9][0-9][0-9]"

REM Check if the status code matches expected
if "!http_status!"=="!expected_status!" (
    echo %PASS_MARK% PASS - Expected status !expected_status!, got !http_status!
    set /a PASSED_COUNT+=1
) else (
    echo %FAIL_MARK% FAIL - Expected status !expected_status!, got !http_status!
    set /a FAILED_COUNT+=1
)
echo.
goto :eof

REM Function to check if service is running
:check_service
echo %INFO_MARK% Checking if messaging service is running...

curl -s -f "%BASE_URL%/health" >nul 2>&1
if errorlevel 1 (
    echo %FAIL_MARK% Service is not running or not accessible
    echo %INFO_MARK% Start the service with: bin\start
    exit /b 1
) else (
    echo %PASS_MARK% Service is running
    echo.
)
goto :eof

echo === Enhanced Messaging Service Test Suite ===
echo Base URL: %BASE_URL%
if not "%SPECIFIC_TEST%"=="" echo Running specific test: %SPECIFIC_TEST%
echo.

REM Check if service is running
call :check_service

echo 📋 Running Comprehensive Field Validation Tests
echo.

REM === VALID TESTS ===
if "%SPECIFIC_TEST%"=="" (
    echo ✅ VALID TESTS
    echo ==============
) else (
    if %SPECIFIC_TEST% leq 8 (
        echo ✅ VALID TESTS
        echo ==============
    )
)

REM Test 1: Valid SMS send
call :run_test "Valid SMS send" "200" "curl -X POST \"%BASE_URL%/api/messages/sms\" -H \"%CONTENT_TYPE%\" -d \"{\\\"from\\\": \\\"+12016661234\\\", \\\"to\\\": \\\"+18045551234\\\", \\\"type\\\": \\\"sms\\\", \\\"body\\\": \\\"Hello! This is a test SMS message.\\\", \\\"attachments\\\": null, \\\"timestamp\\\": \\\"2024-11-01T14:00:00Z\\\"}\" -w \"\nStatus: %%{http_code}\""

REM Test 2: Valid MMS send
call :run_test "Valid MMS send" "200" "curl -X POST \"%BASE_URL%/api/messages/sms\" -H \"%CONTENT_TYPE%\" -d \"{\\\"from\\\": \\\"+12016661234\\\", \\\"to\\\": \\\"+18045551234\\\", \\\"type\\\": \\\"mms\\\", \\\"body\\\": \\\"Hello! This is a test MMS message with attachment.\\\", \\\"attachments\\\": [\\\"https://example.com/image.jpg\\\"], \\\"timestamp\\\": \\\"2024-11-01T14:00:00Z\\\"}\" -w \"\nStatus: %%{http_code}\""

REM Test 3: Valid Email send
call :run_test "Valid Email send" "200" "curl -X POST \"%BASE_URL%/api/messages/email\" -H \"%CONTENT_TYPE%\" -d \"{\\\"from\\\": \\\"user@usehatchapp.com\\\", \\\"to\\\": \\\"contact@gmail.com\\\", \\\"body\\\": \\\"Hello! This is a test email message with <b>HTML</b> formatting.\\\", \\\"attachments\\\": [\\\"https://example.com/document.pdf\\\"], \\\"timestamp\\\": \\\"2024-11-01T14:00:00Z\\\"}\" -w \"\nStatus: %%{http_code}\""

REM Test 4: Valid incoming SMS webhook
call :run_test "Valid incoming SMS webhook" "200" "curl -X POST \"%BASE_URL%/api/webhooks/sms\" -H \"%CONTENT_TYPE%\" -d \"{\\\"from\\\": \\\"+18045551234\\\", \\\"to\\\": \\\"+12016661234\\\", \\\"type\\\": \\\"sms\\\", \\\"messaging_provider_id\\\": \\\"message-1\\\", \\\"body\\\": \\\"This is an incoming SMS message\\\", \\\"attachments\\\": null, \\\"timestamp\\\": \\\"2024-11-01T14:00:00Z\\\"}\" -w \"\nStatus: %%{http_code}\""

REM Test 5: Valid incoming MMS webhook
call :run_test "Valid incoming MMS webhook" "200" "curl -X POST \"%BASE_URL%/api/webhooks/sms\" -H \"%CONTENT_TYPE%\" -d \"{\\\"from\\\": \\\"+18045551234\\\", \\\"to\\\": \\\"+12016661234\\\", \\\"type\\\": \\\"mms\\\", \\\"messaging_provider_id\\\": \\\"message-2\\\", \\\"body\\\": \\\"This is an incoming MMS message\\\", \\\"attachments\\\": [\\\"https://example.com/received-image.jpg\\\"], \\\"timestamp\\\": \\\"2024-11-01T14:00:00Z\\\"}\" -w \"\nStatus: %%{http_code}\""

REM Test 6: Valid incoming Email webhook
call :run_test "Valid incoming Email webhook" "200" "curl -X POST \"%BASE_URL%/api/webhooks/email\" -H \"%CONTENT_TYPE%\" -d \"{\\\"from\\\": \\\"contact@gmail.com\\\", \\\"to\\\": \\\"user@usehatchapp.com\\\", \\\"xillio_id\\\": \\\"message-3\\\", \\\"body\\\": \\\"<html><body>This is an incoming email with <b>HTML</b> content</body></html>\\\", \\\"attachments\\\": [\\\"https://example.com/received-document.pdf\\\"], \\\"timestamp\\\": \\\"2024-11-01T14:00:00Z\\\"}\" -w \"\nStatus: %%{http_code}\""

REM Test 7: Get conversations
call :run_test "Get conversations" "200" "curl -X GET \"%BASE_URL%/api/conversations\" -H \"%CONTENT_TYPE%\" -w \"\nStatus: %%{http_code}\""

REM Test 8: Get messages for conversation
call :run_test "Get messages for conversation" "200" "curl -X GET \"%BASE_URL%/api/conversations/1/messages\" -H \"%CONTENT_TYPE%\" -w \"\nStatus: %%{http_code}\""

echo.
if "%SPECIFIC_TEST%"=="" (
    echo ❌ INVALID FIELD TESTS
    echo =====================
) else (
    if %SPECIFIC_TEST% geq 9 (
        echo ❌ INVALID FIELD TESTS
        echo =====================
    )
)

REM === INVALID FIELD TESTS ===

REM Test 9: Missing required field - from
call :run_test "SMS webhook missing 'from' field" "400" "curl -X POST \"%BASE_URL%/api/webhooks/sms\" -H \"%CONTENT_TYPE%\" -d \"{\\\"to\\\": \\\"+12016661234\\\", \\\"type\\\": \\\"sms\\\", \\\"messaging_provider_id\\\": \\\"message-1\\\", \\\"body\\\": \\\"Missing from field\\\", \\\"timestamp\\\": \\\"2024-11-01T14:00:00Z\\\"}\" -w \"\nStatus: %%{http_code}\""

REM Test 10: Missing required field - to
call :run_test "SMS webhook missing 'to' field" "400" "curl -X POST \"%BASE_URL%/api/webhooks/sms\" -H \"%CONTENT_TYPE%\" -d \"{\\\"from\\\": \\\"+18045551234\\\", \\\"type\\\": \\\"sms\\\", \\\"messaging_provider_id\\\": \\\"message-1\\\", \\\"body\\\": \\\"Missing to field\\\", \\\"timestamp\\\": \\\"2024-11-01T14:00:00Z\\\"}\" -w \"\nStatus: %%{http_code}\""

REM Test 11: Missing required field - type
call :run_test "SMS webhook missing 'type' field" "400" "curl -X POST \"%BASE_URL%/api/webhooks/sms\" -H \"%CONTENT_TYPE%\" -d \"{\\\"from\\\": \\\"+18045551234\\\", \\\"to\\\": \\\"+12016661234\\\", \\\"messaging_provider_id\\\": \\\"message-1\\\", \\\"body\\\": \\\"Missing type field\\\", \\\"timestamp\\\": \\\"2024-11-01T14:00:00Z\\\"}\" -w \"\nStatus: %%{http_code}\""

REM Test 12: Missing required field - messaging_provider_id
call :run_test "SMS webhook missing 'messaging_provider_id' field" "400" "curl -X POST \"%BASE_URL%/api/webhooks/sms\" -H \"%CONTENT_TYPE%\" -d \"{\\\"from\\\": \\\"+18045551234\\\", \\\"to\\\": \\\"+12016661234\\\", \\\"type\\\": \\\"sms\\\", \\\"body\\\": \\\"Missing messaging_provider_id field\\\", \\\"timestamp\\\": \\\"2024-11-01T14:00:00Z\\\"}\" -w \"\nStatus: %%{http_code}\""

REM Test 13: Missing required field - body
call :run_test "SMS webhook missing 'body' field" "400" "curl -X POST \"%BASE_URL%/api/webhooks/sms\" -H \"%CONTENT_TYPE%\" -d \"{\\\"from\\\": \\\"+18045551234\\\", \\\"to\\\": \\\"+12016661234\\\", \\\"type\\\": \\\"sms\\\", \\\"messaging_provider_id\\\": \\\"message-1\\\", \\\"timestamp\\\": \\\"2024-11-01T14:00:00Z\\\"}\" -w \"\nStatus: %%{http_code}\""

REM Test 14: Missing required field - timestamp
call :run_test "SMS webhook missing 'timestamp' field" "400" "curl -X POST \"%BASE_URL%/api/webhooks/sms\" -H \"%CONTENT_TYPE%\" -d \"{\\\"from\\\": \\\"+18045551234\\\", \\\"to\\\": \\\"+12016661234\\\", \\\"type\\\": \\\"sms\\\", \\\"messaging_provider_id\\\": \\\"message-1\\\", \\\"body\\\": \\\"Missing timestamp field\\\"}\" -w \"\nStatus: %%{http_code}\""

REM Test 15: Invalid message type
call :run_test "SMS webhook with invalid 'type' field" "400" "curl -X POST \"%BASE_URL%/api/webhooks/sms\" -H \"%CONTENT_TYPE%\" -d \"{\\\"from\\\": \\\"+18045551234\\\", \\\"to\\\": \\\"+12016661234\\\", \\\"type\\\": \\\"invalid_type\\\", \\\"messaging_provider_id\\\": \\\"message-1\\\", \\\"body\\\": \\\"Invalid type field\\\", \\\"timestamp\\\": \\\"2024-11-01T14:00:00Z\\\"}\" -w \"\nStatus: %%{http_code}\""

REM Test 16: Empty required fields
call :run_test "SMS webhook with empty required fields" "400" "curl -X POST \"%BASE_URL%/api/webhooks/sms\" -H \"%CONTENT_TYPE%\" -d \"{\\\"from\\\": \\\"\\\", \\\"to\\\": \\\"\\\", \\\"type\\\": \\\"sms\\\", \\\"messaging_provider_id\\\": \\\"\\\", \\\"body\\\": \\\"\\\", \\\"timestamp\\\": \\\"\\\"}\" -w \"\nStatus: %%{http_code}\""

REM Test 17: Email webhook missing xillio_id
call :run_test "Email webhook missing 'xillio_id' field" "400" "curl -X POST \"%BASE_URL%/api/webhooks/email\" -H \"%CONTENT_TYPE%\" -d \"{\\\"from\\\": \\\"contact@gmail.com\\\", \\\"to\\\": \\\"user@usehatchapp.com\\\", \\\"body\\\": \\\"Missing xillio_id field\\\", \\\"timestamp\\\": \\\"2024-11-01T14:00:00Z\\\"}\" -w \"\nStatus: %%{http_code}\""

REM Test 18: Invalid JSON format
call :run_test "Invalid JSON format" "500" "curl -X POST \"%BASE_URL%/api/webhooks/sms\" -H \"%CONTENT_TYPE%\" -d \"{\\\"from\\\": \\\"+18045551234\\\", \\\"to\\\": \\\"+12016661234\\\", \\\"type\\\": \\\"sms\\\", \\\"messaging_provider_id\\\": \\\"message-1\\\", \\\"body\\\": \\\"Invalid JSON\\\", \\\"timestamp\\\": \\\"2024-11-01T14:00:00Z\\\"}\" -w \"\nStatus: %%{http_code}\""

REM Test 19: Wrong endpoint for SMS
call :run_test "SMS data sent to email endpoint" "400" "curl -X POST \"%BASE_URL%/api/webhooks/email\" -H \"%CONTENT_TYPE%\" -d \"{\\\"from\\\": \\\"+18045551234\\\", \\\"to\\\": \\\"+12016661234\\\", \\\"type\\\": \\\"sms\\\", \\\"messaging_provider_id\\\": \\\"message-1\\\", \\\"body\\\": \\\"SMS sent to email endpoint\\\", \\\"timestamp\\\": \\\"2024-11-01T14:00:00Z\\\"}\" -w \"\nStatus: %%{http_code}\""

REM Test 20: Non-existent conversation ID
call :run_test "Get messages for non-existent conversation" "200" "curl -X GET \"%BASE_URL%/api/conversations/99999/messages\" -H \"%CONTENT_TYPE%\" -w \"\nStatus: %%{http_code}\""

echo.
echo === TEST RESULTS SUMMARY ===
if not "%SPECIFIC_TEST%"=="" (
    echo Running specific test: %SPECIFIC_TEST%
    echo Passed: !PASSED_COUNT!
    echo Failed: !FAILED_COUNT!
) else (
    echo Total Tests: !TEST_COUNT!
    echo Passed: !PASSED_COUNT!
    echo Failed: !FAILED_COUNT!
)
echo.

REM Overall result
if !FAILED_COUNT! equ 0 (
    if not "%SPECIFIC_TEST%"=="" (
        echo ✅ TEST %SPECIFIC_TEST% PASSED! 🎉
    ) else (
        echo ✅ ALL TESTS PASSED! 🎉
    )
    exit /b 0
) else (
    if not "%SPECIFIC_TEST%"=="" (
        echo ❌ TEST %SPECIFIC_TEST% FAILED! 😞
    ) else (
        echo ❌ SOME TESTS FAILED! 😞
    )
    exit /b 1
)