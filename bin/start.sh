#!/bin/bash

set -e

# Function to show help
show_help() {
    echo "Usage: $0 [PORT]"
    echo
    echo "Start the messaging service on the specified port."
    echo
    echo "Arguments:"
    echo "  PORT    Port number to run the service on (default: 8080)"
    echo "          Valid range: 1-65535"
    echo
    echo "Options:"
    echo "  --help  Show this help message"
    echo
    echo "Examples:"
    echo "  $0              # Start on default port 8080"
    echo "  $0 3000         # Start on port 3000"
    echo "  $0 --help       # Show this help"
    echo
    echo "Environment variables:"
    echo "  ENV     Environment name (default: development)"
}

# Check for help option
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    show_help
    exit 0
fi

# Default port
PORT=${1:-8080}

# Validate port number
if ! [[ "$PORT" =~ ^[0-9]+$ ]]; then
    echo "Error: Port must be a number" >&2
    echo "Use '$0 --help' for usage information" >&2
    exit 1
fi

if [ "$PORT" -lt 1 ] || [ "$PORT" -gt 65535 ]; then
    echo "Error: Port must be between 1 and 65535" >&2
    echo "Use '$0 --help' for usage information" >&2
    exit 1
fi

echo "Starting the messaging service on port $PORT..."
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
echo "Starting messaging service on port $PORT..."
echo "PID: $$" > messaging-service.pid
exec ./build/messaging-service $PORT 