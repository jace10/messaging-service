Jason Mather Implementation

# Backend Interview Project

This is a scaffold for Hatch's backend interview project. It includes basic setup for development, testing, and deployment.

## Quick Start

**Recommended Development Approach (Docker):**
```bash
# Clone and start
git clone <repository-url>
cd messaging-service
./bin/start       # Build and start using Docker
./bin/test        # Run tests
./bin/db-inspect  # Inspect the database manually to double check expected results
./bin/stop        # kills all processes names messaging-service
```

**After making code changes:**
```bash
./bin/stop    # kills all processes names messaging-service
./bin/start   # Rebuild and restart with Docker
./bin/test    # Test your changes
```

**Complete rebuild from scratch:**
```bash
# Option 1: Using start script (Recommended)
./bin/stop
./bin/start

# Option 2: Manual Docker commands
docker-compose down -v --remove-orphans
docker-compose build --no-cache
docker-compose up -d
./bin/test
```

**For detailed instructions, see the [Development](#development) and [Rebuilding from Scratch](#rebuilding-from-scratch) sections below.**

## Guidelines

At Hatch, we work with several message providers to offer a unified way for our Customers to  communicate to their Contacts. Today we offer SMS, MMS, email, voice calls, and voicemail drops. Your task is to implement an HTTP service that supports the core messaging functionality of Hatch, on a much smaller scale. Specific instructions and guidelines on completing the project are below.

### General Guidelines

- You may use whatever programming language, libraries, or frameworks you'd like. 
- We strongly encourage you to use whatever you're most familiar with so that you can showcase your skills and know-how. Candidates will not receive any kind of 'bonus points' or 'red flags' regarding their specific choices of language.
- You are welcome to use AI, Google, StackOverflow, etc as resources while you're developing. We just ask that you understand the code very well, because we will continue developing on it during your onsite interview.
- For ease of assessment, we strongly encourage you to use the `start.sh` script provided in the `bin/` directory, and implement it to run your service. We will run this script to start your project during our assessment. 

### Project-specific guidelines

- Assume that a provider may return HTTP error codes like 500, 429 and plan accordingly
- Conversations consist of messages from multiple providers. Feel free to consult providers such as Twilio or Sendgrid docs when designing your solution, but all external resources should be mocked out by your project. We do not expect you to actually integrate with a third party provider as part of this project.
- It's OK to use Google or a coding assistant to produce your code. Just make sure you know it well, because the next step will be to code additional features in this codebase with us during your full interview.

## Requirements

The service should implement:

- **Unified Messaging API**: HTTP endpoints to send and receive messages from both SMS/MMS and Email providers
  - Support sending messages through the appropriate provider based on message type
  - Handle incoming webhook messages from both providers
- **Conversation Management**: Messages should be automatically grouped into conversations based on participants (from/to addresses)
- **Data Persistence**: All conversations and messages must be stored in a relational database with proper relationships and indexing

### Providers

**SMS & MMS**

**Example outbound payload to send an SMS or MMS**

```json
{
    "from": "from-phone-number",
    "to": "to-phone-number",
    "type": "mms" | "sms",
    "body": "text message",
    "attachments": ["attachment-url"] | [] | null,
    "timestamp": "2024-11-01T14:00:00Z" // UTC timestamp
}
```

**Example inbound SMS**

```json
{
    "from": "+18045551234",
    "to": "+12016661234",
    "type": "sms",
    "messaging_provider_id": "message-1",
    "body": "text message",
    "attachments": null,
    "timestamp": "2024-11-01T14:00:00Z" // UTC timestamp
}
```

**Example inbound MMS**

```json
{
    "from": "+18045551234",
    "to": "+12016661234",
    "type": "mms",
    "messaging_provider_id": "message-2",
    "body": "text message",
    "attachments": ["attachment-url"] | [],
    "timestamp": "2024-11-01T14:00:00Z" // UTC timestamp
}
```

**Email Provider**

**Example Inbound Email**

```json
{
    "from": "[user@usehatchapp.com](mailto:user@usehatchapp.com)",
    "to": "[contact@gmail.com](mailto:contact@gmail.com)",
    "xillio_id": "message-2",
    "body": "<html><body>html is <b>allowed</b> here </body></html>",  "attachments": ["attachment-url"] | [],
    "timestamp": "2024-11-01T14:00:00Z" // UTC timestamp
}
```

**Example Email Payload**

```json
{
    "from": "[user@usehatchapp.com](mailto:user@usehatchapp.com)",
    "to": "[contact@gmail.com](mailto:contact@gmail.com)",
    "body": "text message with or without html",
    "attachments": ["attachment-url"] | [],
    "timestamp": "2024-11-01T14:00:00Z" // UTC timestamp
}
```

### Project Structure

This project structure is laid out for you already. You are welcome to move or change things, just update the Makefile, scripts, and/or docker resources accordingly. As part of the evaluation of your code, we will run 

```
.
├── bin/                    # Scripts and executables
│   ├── start.sh           # Application startup script
│   └── test.sh            # API testing script with curl commands
├── docker-compose.yml      # PostgreSQL database setup
├── Makefile               # Build and development commands with docker-compose integration
└── README.md              # This file
```

## Prerequisites

You have two options for running this project:

### Option 1: Docker Container (Recommended)

**Easiest setup - no local dependencies required!**

- **Docker & Docker Compose** - For running the complete application
  - macOS: Install [Docker Desktop](https://www.docker.com/products/docker-desktop/) or use `brew install colima` for a lightweight alternative
  - Linux: Install Docker and docker-compose

All C++ dependencies (CMake, compiler, cpp-httplib) are included in the Docker container.

### Option 2: Local Development

If you prefer to build locally, ensure you have the following installed:

- **Docker & Docker Compose** - For running PostgreSQL database
  - macOS: Install [Docker Desktop](https://www.docker.com/products/docker-desktop/) or use `brew install colima` for a lightweight alternative
  - Linux: Install Docker and docker-compose

- **CMake** (version 3.16 or higher) - For building the C++ application
  - macOS: `brew install cmake`
  - Linux: `sudo apt-get install cmake` (Ubuntu/Debian) or `sudo yum install cmake` (RHEL/CentOS)

- **C++ Compiler** with C++17 support
  - macOS: Xcode Command Line Tools (`xcode-select --install`)
  - Linux: GCC 7+ or Clang 5+

- **cpp-httplib** - HTTP server library
  - macOS: `brew install cpp-httplib`
  - Linux: Install from source or package manager

### Optional Tools

- **Make** - For running build commands (usually pre-installed)
- **curl** - For testing endpoints (usually pre-installed)
- **Git** - For version control (usually pre-installed)

### Verification

**Docker Container (Recommended):**
```bash
# Verify Docker is installed
docker --version
docker-compose --version

# Test the complete setup
docker-compose up --build
curl http://localhost:8080/health
```

**Local Development:**
You can verify your installation by running:

**macOS/Linux:**
```bash
# Quick dependency check
./bin/check-deps

# Or check manually:
docker --version
docker-compose --version
cmake --version
g++ --version  # or clang++ --version
pkg-config --modversion cpp-httplib
```


## Getting Started

### Option 1: Docker Container (Recommended)

**Quick Start with Docker:**
```bash
# Clone the repository
git clone <repository-url>
cd messaging-service

# Start everything with one command
./bin/start

# Test the service
curl http://localhost:8080/health
curl http://localhost:8080/api/conversations

# Stop the services
./bin/stop
```

**Start Script Commands (Recommended):**
- `./bin/start` - Start all services (database + application) using Docker
- `./bin/stop` - Stop all services
- `./bin/test` - Run tests
- `./bin/start --help` - Show start script help

**Direct Docker Commands (Alternative):**
- `docker-compose up --build` - Start all services (database + application)
- `docker-compose up -d --build` - Start in background
- `docker-compose down` - Stop all services
- `docker-compose logs -f` - View logs
- `docker-compose logs -f messaging-service` - View application logs only

### Option 2: Local Development

**macOS/Linux:**
1. Clone the repository
2. Run `./bin/start` to start the application using Docker
3. Run `./bin/test` to run tests
4. Run `./bin/stop` to stop the application


**Alternative (using Make commands):**
- `make setup` - Initialize the project and start PostgreSQL
- `make build` - Build the C++ application
- `make run` - Start the application
- `make test` - Run tests
- `make stop` - Stop the application

## Available Commands

The project includes several commands for easy development:

### Start Script Commands (Recommended)

- `./bin/start` - Start all services (database + application) using Docker
- `./bin/stop` - Stop all services
- `./bin/test` - Run tests
- `./bin/db-clear` - Nuke the database tables
- `./bin/db-inspect` - Manually inspect the datbase tables
- `./bin/start --help` - Show start script help

### Direct Docker Commands (Alternative)

- `docker-compose up --build` - Start all services (database + application)
- `docker-compose up -d --build` - Start all services in background
- `docker-compose down` - Stop all services
- `docker-compose logs -f` - View logs from all services
- `docker-compose logs -f messaging-service` - View application logs only
- `docker-compose logs -f postgres` - View database logs only
- `docker-compose exec postgres psql -U messaging_user -d messaging_service` - Connect to database

### Local Development Commands

**macOS/Linux (using Make):**
- `make check-deps` - Check if all required dependencies are installed
- `make setup` - Initialize project and start PostgreSQL database
- `make build` - Build the C++ application
- `make run` - Start the messaging service on port 8080 (default)
- `make run PORT=3000` - Start the messaging service on a custom port
- `make stop` - Stop the messaging service
- `make test` - Run endpoint tests
- `make clean` - Stop containers and clean up temporary files
- `make db-up` - Start PostgreSQL database only
- `make db-down` - Stop PostgreSQL database only
- `make db-logs` - Show database logs
- `make db-shell` - Connect to database shell
- `make help` - Show all available commands


## Development

### Docker Development (Recommended)

The easiest way to develop is using Docker containers. **This is the recommended approach** as it requires no local dependencies and ensures consistent builds across different environments.

#### Quick Development Workflow

```bash
# After making source changes:
./bin/start   # Builds and starts using Docker (includes all dependencies)
./bin/test    # Run your tests
./bin/stop    # Stop when done
```

#### Detailed Docker Commands

```bash
# Start all services
docker-compose up --build

# View logs
docker-compose logs -f messaging-service

# Connect to database
docker-compose exec postgres psql -U messaging_user -d messaging_service

# Stop services
docker-compose down
```

#### Development Process After Code Changes

**Option 1: Using Start Script (Recommended)**
```bash
# After making source changes:
./bin/start   # Builds and starts using Docker
./bin/test    # Test your changes
./bin/stop    # Stop when done
```

**Option 2: Using Make Commands**
```bash
# After making source changes:
make build    # Builds using Docker
make run      # Starts using Docker
./bin/test    # Test your changes
```

**Option 3: Full Rebuild (When you want to ensure clean build)**
```bash
# After making source changes:
docker-compose down
docker-compose build --no-cache messaging-service
docker-compose up -d
./bin/test
```

### Local Development (Advanced)

**⚠️ Note: Local development requires installing C++ dependencies locally. Docker development is recommended.**

If you prefer local development, you'll need to install all dependencies locally:

#### Prerequisites for Local Development

- **CMake** (version 3.16 or higher)
- **C++ Compiler** with C++17 support
- **cpp-httplib** library
- **PostgreSQL development libraries**
- **Docker** (for database only)

#### Local Development Workflow

```bash
# Start PostgreSQL database
make db-up

# Build locally (requires local dependencies)
make build

# Run locally
make run

# Test
make test

# Stop
make stop
```

#### Local Development Commands

- Use `make setup` to start PostgreSQL database and initialize the project
- Use `make build` to build the C++ application locally
- Use `make run` to start the development server (default port 8080)
- Use `make run PORT=3000` to start on a custom port
- Use `make test` to run tests
- Use `make stop` to stop the application
- Use `make clean` to stop containers and clean up

### Port Configuration

The messaging service runs on port 8080 by default, but you can specify a custom port:

**macOS/Linux:**
```bash
# Default port (8080) - Recommended
./bin/start

# Custom port - Recommended
./bin/start 3000

# Show help for start script
./bin/start --help

# Alternative: Using Make commands
make run              # Default port (8080)
make run PORT=3000    # Custom port

# Alternative: Direct executable usage
./build/messaging-service 3000

# Database inspection
./bin/db-inspect                    # Show all tables and data
./bin/db-inspect --conversations    # Show only conversations
./bin/db-inspect --messages         # Show only messages
./bin/db-inspect --counts           # Show only row counts
./bin/db-inspect --help             # Show all options

# Database clearing (⚠️ WARNING: Deletes data!)
./bin/db-clear                      # Clear all tables with confirmation
./bin/db-clear --confirm            # Clear all tables without confirmation
./bin/db-clear --messages           # Clear only messages table
./bin/db-clear --conversations      # Clear only conversations table
./bin/db-clear --reset              # Clear all and reset sequences
./bin/db-clear --help               # Show all options
```


The application validates that the port is between 1 and 65535 and will show an error message for invalid ports. Both the start script and the C++ executable provide helpful error messages and usage information.

## Rebuilding from Scratch

Sometimes you need to completely rebuild the project from scratch. This is useful when:
- You've made significant changes to dependencies
- You're experiencing build issues
- You want to ensure a completely clean build
- You're switching between different development approaches

### Complete Clean Rebuild (Docker)

**Option 1: Using Start Script (Recommended)**
```bash
# Simple rebuild using start script
./bin/stop
./bin/start
./bin/test
```

**Option 2: Manual Docker Commands (Most Thorough)**
```bash
# 1. Stop all running containers
docker-compose down

# 2. Remove all containers, networks, and volumes
docker-compose down -v --remove-orphans

# 3. Remove the Docker image (optional, forces complete rebuild)
docker rmi messaging-service-messaging-service:latest

# 4. Remove any local build artifacts
rm -rf build/

# 5. Rebuild everything from scratch
docker-compose build --no-cache

# 6. Start the services
docker-compose up -d

# 7. Verify everything is working
./bin/test
```

### Quick Clean Rebuild (Docker)

**Option 1: Using Start Script (Recommended)**
```bash
# Simple rebuild using start script
./bin/stop
./bin/start
./bin/test
```

**Option 2: Manual Docker Commands**
```bash
# 1. Stop services
docker-compose down

# 2. Rebuild without cache
docker-compose build --no-cache messaging-service

# 3. Start services
docker-compose up -d

# 4. Test
./bin/test
```

### Complete Clean Rebuild (Local Development)

**If you're using local development:**

```bash
# 1. Stop any running services
make stop

# 2. Clean build directory
rm -rf build/

# 3. Clean Docker containers (if using Docker for database)
docker-compose down -v

# 4. Rebuild everything
make setup    # Start database
make build    # Build application
make run      # Start application

# 5. Test
make test
```

### Troubleshooting Build Issues

**If you're experiencing build problems:**

1. **Check Docker is running:**
   ```bash
   docker --version
   docker-compose --version
   ```

2. **Check available disk space:**
   ```bash
   df -h  # Linux/macOS
   ```

3. **Clear Docker cache:**
   ```bash
   docker system prune -a
   ```

4. **Check for port conflicts:**
   ```bash
   lsof -i :8080  # Check if port 8080 is in use
   ```

5. **Verify database is healthy:**
   ```bash
   docker-compose logs postgres
   ```

6. **Check application logs:**
   ```bash
   docker-compose logs messaging-service
   ```

### Development Environment Reset

**Option 1: Using Start Script (Recommended)**
```bash
# Simple reset using start script
./bin/stop
./bin/start
```

**Option 2: Complete Reset (Manual)**
```bash
# 1. Stop everything
docker-compose down -v --remove-orphans

# 2. Remove all Docker images and containers
docker system prune -a

# 3. Remove local build artifacts
rm -rf build/

# 4. Start fresh
docker-compose up --build
```

## Database

The application uses PostgreSQL as its database. The docker-compose.yml file sets up:
- PostgreSQL 15 with Alpine Linux
- Database: `messaging_service`
- User: `messaging_user`
- Password: `messaging_password`
- Port: `5432` (exposed to host)

### Docker Database Access

To connect to the database when using Docker:

```bash
# Connect to database shell
docker-compose exec postgres psql -U messaging_user -d messaging_service

# View database logs
docker-compose logs -f postgres
```

### Local Development Database Access

If running locally with `make`:

```bash
# Connect to database shell
docker-compose exec postgres psql -U messaging_user -d messaging_service
```

The database schema is automatically initialized with tables for conversations and messages, including sample data for testing.

## Docker Setup

For detailed Docker instructions, troubleshooting, and production considerations, see [DOCKER.md](DOCKER.md).

The Docker setup includes:
- **Complete C++ build environment** with all dependencies
- **PostgreSQL database** with automatic schema initialization
- **Health checks** for both services
- **Production-ready configuration** with security best practices
- **Easy development workflow** with hot reloading support
