#!/bin/bash

set -e

echo "Starting the messaging service..."
echo "Environment: ${ENV:-development}"

# Create build directory if it doesn't exist
mkdir -p build

# Build the C++ application
echo "Building C++ application..."
cd build
cmake ..
make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu)
cd ..

# Start the application
echo "Starting messaging service on port 8080..."
echo "PID: $$" > messaging-service.pid
exec ./build/messaging-service 