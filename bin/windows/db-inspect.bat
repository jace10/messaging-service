@echo off
setlocal enabledelayedexpansion

REM Database inspection script for Windows
REM Displays database tables and data in a readable format

REM Default values
set SHOW_TABLES=true
set SHOW_DATA=true
set SHOW_CONVERSATIONS=true
set SHOW_MESSAGES=true
set SHOW_COUNTS=false

REM Parse command line arguments
:parse_args
if "%~1"=="" goto :start_inspection
if "%~1"=="--help" goto :show_help
if "%~1"=="-h" goto :show_help
if "%~1"=="--tables" goto :set_tables_only
if "%~1"=="-t" goto :set_tables_only
if "%~1"=="--data" goto :set_data_only
if "%~1"=="-d" goto :set_data_only
if "%~1"=="--conversations" goto :set_conversations_only
if "%~1"=="--messages" goto :set_messages_only
if "%~1"=="--counts" goto :set_counts_only

echo Unknown option: %~1
echo Use '%0 --help' for usage information
exit /b 1

:set_tables_only
set SHOW_TABLES=true
set SHOW_DATA=false
set SHOW_CONVERSATIONS=false
set SHOW_MESSAGES=false
set SHOW_COUNTS=false
shift
goto :parse_args

:set_data_only
set SHOW_TABLES=false
set SHOW_DATA=true
set SHOW_CONVERSATIONS=false
set SHOW_MESSAGES=false
set SHOW_COUNTS=false
shift
goto :parse_args

:set_conversations_only
set SHOW_TABLES=false
set SHOW_DATA=false
set SHOW_CONVERSATIONS=true
set SHOW_MESSAGES=false
set SHOW_COUNTS=false
shift
goto :parse_args

:set_messages_only
set SHOW_TABLES=false
set SHOW_DATA=false
set SHOW_CONVERSATIONS=false
set SHOW_MESSAGES=true
set SHOW_COUNTS=false
shift
goto :parse_args

:set_counts_only
set SHOW_TABLES=false
set SHOW_DATA=false
set SHOW_CONVERSATIONS=false
set SHOW_MESSAGES=false
set SHOW_COUNTS=true
shift
goto :parse_args

:show_help
echo Usage: %0 [OPTIONS]
echo.
echo Display database tables and data in a readable format.
echo.
echo Options:
echo   --help, -h     Show this help message
echo   --tables, -t   Show only table structure
echo   --data, -d     Show only table data
echo   --conversations Show only conversations table
echo   --messages     Show only messages table
echo   --counts       Show only row counts
echo.
echo Examples:
echo   %0                    # Show all tables and data
echo   %0 --tables           # Show only table structure
echo   %0 --data             # Show only table data
echo   %0 --conversations    # Show only conversations
echo   %0 --messages         # Show only messages
echo   %0 --counts           # Show only row counts
exit /b 0

:start_inspection
echo 📊 Messaging Service Database Inspector
echo =====================================
echo.

REM Database connection parameters
if not defined DB_HOST set DB_HOST=localhost
if not defined DB_PORT set DB_PORT=5432
if not defined DB_NAME set DB_NAME=messaging_service
if not defined DB_USER set DB_USER=messaging_user
if not defined DB_PASSWORD set DB_PASSWORD=messaging_password

echo 🔍 Checking database connection...

REM Check if psql is available
where psql >nul 2>&1
if errorlevel 1 (
    echo ❌ psql not found. Please install PostgreSQL client tools.
    echo 💡 Install PostgreSQL from https://www.postgresql.org/download/windows/
    echo    or use Docker: docker-compose up -d postgres
    exit /b 1
)

REM Test database connection
set PGPASSWORD=%DB_PASSWORD%
psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -c "SELECT 1;" >nul 2>&1
if errorlevel 1 (
    echo ❌ Cannot connect to database
    echo 💡 Make sure the database is running:
    echo    docker-compose up -d postgres
    echo    or start your local PostgreSQL service
    exit /b 1
)

echo ✅ Database connection successful
echo.

REM Show table structure
if "%SHOW_TABLES%"=="true" (
    echo 📋 Table Structure
    echo ==================
    psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -c "SELECT table_name, column_name, data_type, is_nullable, column_default FROM information_schema.columns WHERE table_schema = 'public' AND table_name IN ('conversations', 'messages') ORDER BY table_name, ordinal_position;"
    echo.
)

REM Show row counts
if "%SHOW_COUNTS%"=="true" (
    echo 📊 Row Counts
    echo ==============
    psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -c "SELECT 'conversations' as table_name, COUNT(*) as row_count FROM conversations UNION ALL SELECT 'messages' as table_name, COUNT(*) as row_count FROM messages;"
    echo.
)

REM Show conversations data
if "%SHOW_CONVERSATIONS%"=="true" (
    echo 💬 Conversations
    echo ================
    psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -c "SELECT id, participant_from, participant_to, created_at, updated_at FROM conversations ORDER BY created_at DESC;"
    echo.
)

REM Show messages data
if "%SHOW_MESSAGES%"=="true" (
    echo 📨 Recent Messages (Last 20)
    echo =============================
    psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -c "SELECT m.id, m.conversation_id, m.from_address, m.to_address, m.message_type, LEFT(m.body, 50) || CASE WHEN LENGTH(m.body) > 50 THEN '...' ELSE '' END as body_preview, m.messaging_provider_id, m.xillio_id, m.timestamp, m.direction, m.created_at FROM messages m ORDER BY m.timestamp DESC LIMIT 20;"
    echo.
)

REM Show summary statistics
if "%SHOW_DATA%"=="true" (
    echo 📈 Summary Statistics
    echo ====================
    psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -c "SELECT 'Total Conversations' as metric, COUNT(*)::text as value FROM conversations UNION ALL SELECT 'Total Messages' as metric, COUNT(*)::text as value FROM messages UNION ALL SELECT 'SMS Messages' as metric, COUNT(*)::text as value FROM messages WHERE message_type = 'sms' UNION ALL SELECT 'MMS Messages' as metric, COUNT(*)::text as value FROM messages WHERE message_type = 'mms' UNION ALL SELECT 'Email Messages' as metric, COUNT(*)::text as value FROM messages WHERE message_type = 'email' UNION ALL SELECT 'Inbound Messages' as metric, COUNT(*)::text as value FROM messages WHERE direction = 'inbound' UNION ALL SELECT 'Outbound Messages' as metric, COUNT(*)::text as value FROM messages WHERE direction = 'outbound';"
    echo.
)

echo ✅ Database inspection complete
echo 💡 Use '%0 --help' for more options
