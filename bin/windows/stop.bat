@echo off
setlocal

echo Stopping the messaging service...

REM Find and kill ALL messaging-service processes
echo Searching for messaging-service processes...

REM Try graceful shutdown first
taskkill /im messaging-service.exe >nul 2>&1
if %errorlevel% equ 0 (
    echo Found messaging-service processes, attempting graceful shutdown...
    timeout /t 2 /nobreak >nul
    
    REM Check if processes are still running and force kill if needed
    taskkill /f /im messaging-service.exe >nul 2>&1
    if %errorlevel% equ 0 (
        echo Some processes still running, force killing...
        timeout /t 1 /nobreak >nul
        
        REM Final check
        taskkill /f /im messaging-service.exe >nul 2>&1
        if %errorlevel% equ 0 (
            echo Warning: Some processes may still be running
        ) else (
            echo All messaging-service processes stopped.
        )
    ) else (
        echo All messaging-service processes stopped gracefully.
    )
) else (
    echo No messaging-service processes found.
)

REM Clean up PID file if it exists
if exist messaging-service.pid (
    echo Removing PID file...
    del messaging-service.pid
)

echo Cleanup complete.

endlocal
