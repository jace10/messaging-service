@echo off
setlocal

echo Stopping the messaging service...

REM Stop Docker containers
echo Stopping Docker containers...
docker-compose down

echo Cleanup complete.

endlocal
