#!/bin/bash

# Dependency check script for messaging-service
# This script checks if all required dependencies are installed

set -e

echo "🔍 Checking dependencies for messaging-service..."
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if command exists
check_command() {
    if command -v "$1" &> /dev/null; then
        echo -e "${GREEN}✅ $1${NC} - $(command -v "$1")"
        return 0
    else
        echo -e "${RED}❌ $1${NC} - Not found"
        return 1
    fi
}

# Function to check version
check_version() {
    local cmd="$1"
    local min_version="$2"
    local version_cmd="$3"
    
    if check_command "$cmd"; then
        if [ -n "$version_cmd" ]; then
            local version=$($version_cmd 2>/dev/null | head -n1)
            echo -e "   Version: ${YELLOW}$version${NC}"
        fi
    fi
}

echo "📋 Required Dependencies:"
echo

# Check Docker
echo "🐳 Docker & Docker Compose:"
check_version "docker" "20.0" "docker --version"
check_version "docker-compose" "1.25" "docker-compose --version"
echo

# Check CMake
echo "🔨 Build Tools:"
check_version "cmake" "3.16" "cmake --version"
echo

# Check C++ Compiler
echo "⚙️  C++ Compiler:"
if check_command "g++"; then
    check_version "g++" "7.0" "g++ --version"
elif check_command "clang++"; then
    check_version "clang++" "5.0" "clang++ --version"
else
    echo -e "${RED}❌ No C++ compiler found (need g++ or clang++)${NC}"
fi
echo

# Check cpp-httplib
echo "📚 Libraries:"
if check_command "pkg-config"; then
    if pkg-config --exists cpp-httplib; then
        local version=$(pkg-config --modversion cpp-httplib)
        echo -e "${GREEN}✅ cpp-httplib${NC} - Version: ${YELLOW}$version${NC}"
    else
        echo -e "${RED}❌ cpp-httplib${NC} - Not found"
        echo -e "   Install with: ${YELLOW}brew install cpp-httplib${NC} (macOS)"
    fi
else
    echo -e "${YELLOW}⚠️  pkg-config${NC} - Not found (needed to check cpp-httplib)"
fi
echo

# Check optional tools
echo "🔧 Optional Tools:"
check_command "make"
check_command "curl"
check_command "git"
echo

echo "📖 Installation Instructions:"
echo
echo "macOS:"
echo "  brew install docker cmake cpp-httplib"
echo "  # Or install Docker Desktop from https://docker.com"
echo
echo "Ubuntu/Debian:"
echo "  sudo apt-get update"
echo "  sudo apt-get install docker.io docker-compose cmake g++ libcpp-httplib-dev"
echo
echo "RHEL/CentOS:"
echo "  sudo yum install docker cmake gcc-c++"
echo "  # Install cpp-httplib from source or use package manager"
echo

echo "🚀 Once all dependencies are installed, run:"
echo "  make setup"
echo "  make build"
echo "  make run"
