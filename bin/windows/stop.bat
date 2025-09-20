@echo off
setlocal

echo Stopping the messaging service...

REM Check if PID file exists
if exist messaging-service.pid (
    echo Found PID file
    REM On Windows, we'll use taskkill to stop the process
    taskkill /f /im messaging-service.exe >nul 2>&1
    if %errorlevel% equ 0 (
        echo Messaging service stopped.
    ) else (
        echo No messaging-service process found.
    )
    
    REM Clean up PID file
    del messaging-service.pid
) else (
    echo No PID file found. Attempting to find and stop messaging-service process...
    
    REM Find and kill any running messaging-service processes
    taskkill /f /im messaging-service.exe >nul 2>&1
    if %errorlevel% equ 0 (
        echo Messaging service stopped.
    ) else (
        echo No messaging-service processes found.
    )
)

echo Cleanup complete.

endlocal
