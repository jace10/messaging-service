#!/bin/bash

set -e

echo "Stopping the messaging service..."

# Check if PID file exists
if [ -f messaging-service.pid ]; then
    PID=$(cat messaging-service.pid)
    echo "Found PID: $PID"
    
    # Check if process is still running
    if ps -p $PID > /dev/null 2>&1; then
        echo "Stopping process $PID..."
        kill $PID
        
        # Wait for graceful shutdown
        sleep 2
        
        # Force kill if still running
        if ps -p $PID > /dev/null 2>&1; then
            echo "Force stopping process $PID..."
            kill -9 $PID
        fi
        
        echo "Messaging service stopped."
    else
        echo "Process $PID is not running."
    fi
    
    # Clean up PID file
    rm -f messaging-service.pid
else
    echo "No PID file found. Attempting to find and stop messaging-service process..."
    
    # Find and kill any running messaging-service processes
    PIDS=$(pgrep -f messaging-service || true)
    if [ -n "$PIDS" ]; then
        echo "Found messaging-service processes: $PIDS"
        kill $PIDS
        sleep 2
        # Force kill if still running
        PIDS=$(pgrep -f messaging-service || true)
        if [ -n "$PIDS" ]; then
            kill -9 $PIDS
        fi
        echo "Messaging service stopped."
    else
        echo "No messaging-service processes found."
    fi
fi

echo "Cleanup complete."
