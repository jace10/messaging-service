#!/bin/bash

set -e

echo "Stopping the messaging service..."

# Stop Docker containers
echo "Stopping Docker containers..."
docker-compose down

echo "Cleanup complete."
