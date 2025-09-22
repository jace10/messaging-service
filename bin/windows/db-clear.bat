@echo off
setlocal enabledelayedexpansion

REM Database clearing script for Windows
REM Clears database tables and optionally resets sequences

REM Default values
set CLEAR_MESSAGES=true
set CLEAR_CONVERSATIONS=true
set RESET_SEQUENCES=false
set SKIP_CONFIRMATION=false

REM Parse command line arguments
:parse_args
if "%~1"=="" goto :start_clearing
if "%~1"=="--help" goto :show_help
if "%~1"=="-h" goto :show_help
if "%~1"=="--confirm" goto :set_confirm
if "%~1"=="-y" goto :set_confirm
if "%~1"=="--messages" goto :set_messages_only
if "%~1"=="--conversations" goto :set_conversations_only
if "%~1"=="--all" goto :set_all
if "%~1"=="--reset" goto :set_reset

echo Unknown option: %~1
echo Use '%0 --help' for usage information
exit /b 1

:set_confirm
set SKIP_CONFIRMATION=true
shift
goto :parse_args

:set_messages_only
set CLEAR_MESSAGES=true
set CLEAR_CONVERSATIONS=false
set RESET_SEQUENCES=false
shift
goto :parse_args

:set_conversations_only
set CLEAR_MESSAGES=false
set CLEAR_CONVERSATIONS=true
set RESET_SEQUENCES=false
shift
goto :parse_args

:set_all
set CLEAR_MESSAGES=true
set CLEAR_CONVERSATIONS=true
set RESET_SEQUENCES=false
shift
goto :parse_args

:set_reset
set CLEAR_MESSAGES=true
set CLEAR_CONVERSATIONS=true
set RESET_SEQUENCES=true
shift
goto :parse_args

:show_help
echo Usage: %0 [OPTIONS]
echo.
echo Clear database tables and reset data.
echo.
echo Options:
echo   --help, -h     Show this help message
echo   --confirm, -y Skip confirmation prompt
echo   --messages     Clear only messages table
echo   --conversations Clear only conversations table
echo   --all          Clear all tables (default)
echo   --reset        Clear all tables and reset sequences
echo.
echo Examples:
echo   %0                    # Clear all tables with confirmation
echo   %0 --confirm          # Clear all tables without confirmation
echo   %0 --messages         # Clear only messages table
echo   %0 --conversations    # Clear only conversations table
echo   %0 --reset            # Clear all and reset auto-increment sequences
echo.
echo ⚠️  WARNING: This will permanently delete data!
echo    Make sure you have backups if needed.
exit /b 0

:start_clearing
echo 🗑️  Messaging Service Database Cleaner
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

REM Show current data counts before clearing
echo 📊 Current Data Counts:
echo ======================
psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -c "SELECT 'conversations' as table_name, COUNT(*) as row_count FROM conversations UNION ALL SELECT 'messages' as table_name, COUNT(*) as row_count FROM messages;"
echo.

REM Confirmation prompt
if "%SKIP_CONFIRMATION%"=="false" (
    echo ⚠️  WARNING: This will permanently delete data!
    echo.
    
    if "%CLEAR_MESSAGES%"=="true" if "%CLEAR_CONVERSATIONS%"=="true" (
        echo You are about to clear ALL tables (conversations and messages)
    ) else if "%CLEAR_MESSAGES%"=="true" (
        echo You are about to clear the MESSAGES table only
    ) else if "%CLEAR_CONVERSATIONS%"=="true" (
        echo You are about to clear the CONVERSATIONS table only
    )
    
    if "%RESET_SEQUENCES%"=="true" (
        echo Sequences will also be reset to start from 1
    )
    
    echo.
    set /p "confirm=Are you sure you want to continue? (yes/no): "
    if /i not "!confirm!"=="yes" (
        echo ✅ Operation cancelled
        exit /b 0
    )
)

REM Clear tables
echo 🗑️  Clearing database...

if "%CLEAR_MESSAGES%"=="true" (
    echo Clearing Messages Table
    echo ========================
    psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -c "DELETE FROM messages;"
    echo.
)

if "%CLEAR_CONVERSATIONS%"=="true" (
    echo Clearing Conversations Table
    echo =============================
    psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -c "DELETE FROM conversations;"
    echo.
)

REM Reset sequences if requested
if "%RESET_SEQUENCES%"=="true" (
    echo Resetting Sequences
    echo ===================
    psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -c "ALTER SEQUENCE conversations_id_seq RESTART WITH 1; ALTER SEQUENCE messages_id_seq RESTART WITH 1;"
    echo.
)

REM Show final counts
echo 📊 Final Data Counts:
echo =====================
psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -c "SELECT 'conversations' as table_name, COUNT(*) as row_count FROM conversations UNION ALL SELECT 'messages' as table_name, COUNT(*) as row_count FROM messages;"
echo.

echo ✅ Database clearing complete
echo 💡 Use '%0 --help' for more options
