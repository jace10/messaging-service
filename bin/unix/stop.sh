#!/bin/bash

set -e

echo "Stopping the messaging service..."

# Find and kill ALL messaging-service processes
echo "Searching for messaging-service processes..."
PIDS=$(pgrep -f "messaging-service" || true)

if [ -n "$PIDS" ]; then
    echo "Found messaging-service processes: $PIDS"
    
    # Graceful shutdown first
    echo "Attempting graceful shutdown..."
    kill $PIDS 2>/dev/null || true
    
    # Wait for graceful shutdown
    sleep 2
    
    # Check if any processes are still running
    REMAINING_PIDS=$(pgrep -f "messaging-service" || true)
    if [ -n "$REMAINING_PIDS" ]; then
        echo "Some processes still running, force killing: $REMAINING_PIDS"
        kill -9 $REMAINING_PIDS 2>/dev/null || true
        sleep 1
        
        # Final check
        FINAL_PIDS=$(pgrep -f "messaging-service" || true)
        if [ -n "$FINAL_PIDS" ]; then
            echo "Warning: Some processes may still be running: $FINAL_PIDS"
        else
            echo "All messaging-service processes stopped."
        fi
    else
        echo "All messaging-service processes stopped gracefully."
    fi
else
    echo "No messaging-service processes found."
fi

# Clean up PID file if it exists
if [ -f messaging-service.pid ]; then
    echo "Removing PID file..."
    rm -f messaging-service.pid
fi

echo "Cleanup complete."
