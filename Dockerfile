# Use Ubuntu 22.04 as base image for better compatibility
FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV CMAKE_BUILD_TYPE=Release

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    pkg-config \
    libssl-dev \
    libpq-dev \
    postgresql-client \
    curl \
    nlohmann-json3-dev \
    && rm -rf /var/lib/apt/lists/*

# Install cpp-httplib from source
WORKDIR /tmp
RUN git clone https://github.com/yhirose/cpp-httplib.git && \
    cd cpp-httplib && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make -j$(nproc) && \
    make install && \
    cd / && \
    rm -rf /tmp/cpp-httplib

# Set working directory
WORKDIR /app

# Copy source code
COPY src/ ./src/
COPY tests/ ./tests/
COPY CMakeLists.txt ./

# Create build directory and build the application
RUN mkdir -p build && \
    cd build && \
    cmake .. && \
    make -j$(nproc)

# Create a non-root user for security
RUN useradd -m -s /bin/bash appuser && \
    chown -R appuser:appuser /app
USER appuser

# Expose port
EXPOSE 8080

# Set default command
CMD ["./build/messaging-service", "8080"]
