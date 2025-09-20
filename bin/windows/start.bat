@echo off
setlocal enabledelayedexpansion

REM Function to show help
:show_help
echo Usage: %~nx0 [PORT]
echo.
echo Start the messaging service on the specified port.
echo.
echo Arguments:
echo   PORT    Port number to run the service on (default: 8080)
echo           Valid range: 1-65535
echo.
echo Options:
echo   --help  Show this help message
echo.
echo Examples:
echo   %~nx0              # Start on default port 8080
echo   %~nx0 3000         # Start on port 3000
echo   %~nx0 --help       # Show this help
echo.
echo Environment variables:
echo   ENV     Environment name (default: development)
exit /b 0

REM Check for help option
if "%1"=="--help" goto show_help
if "%1"=="-h" goto show_help

REM Default port
set "PORT=%1"
if "%PORT%"=="" set "PORT=8080"

REM Validate port number
echo %PORT% | findstr /r "^[0-9][0-9]*$" >nul
if %errorlevel% neq 0 (
    echo Error: Port must be a number >&2
    echo Use '%~nx0 --help' for usage information >&2
    exit /b 1
)

if %PORT% lss 1 (
    echo Error: Port must be between 1 and 65535 >&2
    echo Use '%~nx0 --help' for usage information >&2
    exit /b 1
)

if %PORT% gtr 65535 (
    echo Error: Port must be between 1 and 65535 >&2
    echo Use '%~nx0 --help' for usage information >&2
    exit /b 1
)

echo Starting the messaging service on port %PORT%...
echo Environment: %ENV%
if "%ENV%"=="" echo Environment: development

REM Create build directory if it doesn't exist
if not exist build mkdir build

REM Build the C++ application
echo Building C++ application...
cd build
cmake ..
cmake --build . --config Release
cd ..

REM Start the application
echo Starting messaging service on port %PORT%...
echo PID: %CD% > messaging-service.pid
start /b .\build\Release\messaging-service.exe %PORT%

endlocal
