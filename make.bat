@echo off
REM Windows-compatible Makefile for messaging-service
REM Usage: make.bat [target]

setlocal enabledelayedexpansion

if "%1"=="" goto help
if "%1"=="help" goto help
if "%1"=="setup" goto setup
if "%1"=="build" goto build
if "%1"=="run" goto run
if "%1"=="stop" goto stop
if "%1"=="test" goto test
if "%1"=="clean" goto clean
if "%1"=="check-deps" goto check-deps
if "%1"=="db-up" goto db-up
if "%1"=="db-down" goto db-down
if "%1"=="db-logs" goto db-logs
if "%1"=="db-shell" goto db-shell
goto help

:help
echo Available commands:
echo   setup      - Set up the project environment and start database
echo   build      - Build the C++ application
echo   run        - Run the application (default port 8080)
echo             - Usage: make.bat run PORT=3000
echo   stop       - Stop the application
echo   test       - Run tests
echo   clean      - Clean up temporary files and stop containers
echo   check-deps - Check if all required dependencies are installed
echo   db-up      - Start the PostgreSQL database
echo   db-down    - Stop the PostgreSQL database
echo   db-logs    - Show database logs
echo   db-shell   - Connect to the database shell
echo   help       - Show this help message
goto end

:setup
echo Setting up the project...
echo Starting PostgreSQL database...
docker-compose up -d
echo Waiting for database to be ready...
timeout /t 5 /nobreak >nul
echo Setup complete!
goto end

:build
echo Building C++ application...
if not exist build mkdir build
cd build
cmake ..
cmake --build . --config Release
cd ..
goto end

:run
echo Running the application...
if "%PORT%"=="" set "PORT=8080"
call bin\start %PORT%
goto end

:stop
echo Stopping the application...
call bin\stop
goto end

:test
echo Running tests...
echo Starting test database if not running...
docker-compose up -d
echo Running test script...
call bin\test
goto end

:clean
echo Cleaning up...
echo Stopping and removing containers...
docker-compose down -v
echo Removing any temporary files...
if exist *.log del *.log
if exist *.tmp del *.tmp
if exist messaging-service.pid del messaging-service.pid
goto end

:check-deps
echo Checking dependencies...
call bin\check-deps
goto end

:db-up
echo Starting PostgreSQL database...
docker-compose up -d
goto end

:db-down
echo Stopping PostgreSQL database...
docker-compose down
goto end

:db-logs
echo Showing database logs...
docker-compose logs -f postgres
goto end

:db-shell
echo Connecting to database shell...
docker-compose exec postgres psql -U messaging_user -d messaging_service
goto end

:end
endlocal
