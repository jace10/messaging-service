Jason Mather Implementation

# Backend Interview Project

This is a scaffold for Hatch's backend interview project. It includes basic setup for development, testing, and deployment.

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
├── bin/                    # Platform-agnostic script wrappers
│   ├── start              # Cross-platform start script wrapper
│   ├── stop               # Cross-platform stop script wrapper
│   ├── test               # Cross-platform test script wrapper
│   ├── check-deps         # Cross-platform dependency checker wrapper
│   ├── db-inspect         # Cross-platform database inspection script
│   ├── unix/              # Unix-specific scripts (macOS/Linux)
│   │   ├── start.sh       # Unix start script
│   │   ├── stop.sh        # Unix stop script
│   │   ├── test.sh        # Unix test script
│   │   ├── check-deps.sh  # Unix dependency checker
│   │   └── db-inspect.sh  # Unix database inspection script
│   └── windows/           # Windows-specific scripts
│       ├── start.bat      # Windows start script
│       ├── stop.bat       # Windows stop script
│       ├── test.bat       # Windows test script
│       ├── check-deps.bat # Windows dependency checker
│       └── db-inspect.bat # Windows database inspection script
├── src/                    # C++ source code
│   ├── main.cpp           # Application entry point
│   ├── server/            # HTTP server implementation
│   │   ├── server.h       # Server class definition
│   │   └── server.cpp     # Server setup and routing
│   └── handlers/          # Request handlers
│       ├── message_handler.h/.cpp      # SMS/Email sending endpoints
│       ├── webhook_handler.h/.cpp      # Incoming webhook endpoints
│       └── conversation_handler.h/.cpp  # Conversation management endpoints
├── build/                  # Build directory (created by CMake)
├── CMakeLists.txt         # CMake build configuration
├── docker-compose.yml      # PostgreSQL database setup
├── Makefile               # Build and development commands (Unix)
├── make.bat               # Build and development commands (Windows)
└── README.md              # This file
```

## Prerequisites

You have two options for running this project:

### Option 1: Docker Container (Recommended)

**Easiest setup - no local dependencies required!**

- **Docker & Docker Compose** - For running the complete application
  - macOS: Install [Docker Desktop](https://www.docker.com/products/docker-desktop/) or use `brew install colima` for a lightweight alternative
  - Linux: Install Docker and docker-compose
  - Windows: Install [Docker Desktop](https://www.docker.com/products/docker-desktop/)

All C++ dependencies (CMake, compiler, cpp-httplib) are included in the Docker container.

### Option 2: Local Development

If you prefer to build locally, ensure you have the following installed:

- **Docker & Docker Compose** - For running PostgreSQL database
  - macOS: Install [Docker Desktop](https://www.docker.com/products/docker-desktop/) or use `brew install colima` for a lightweight alternative
  - Linux: Install Docker and docker-compose
  - Windows: Install [Docker Desktop](https://www.docker.com/products/docker-desktop/)

- **CMake** (version 3.16 or higher) - For building the C++ application
  - macOS: `brew install cmake`
  - Linux: `sudo apt-get install cmake` (Ubuntu/Debian) or `sudo yum install cmake` (RHEL/CentOS)
  - Windows: Download from [cmake.org](https://cmake.org/download/) or use `winget install Kitware.CMake`

- **C++ Compiler** with C++17 support
  - macOS: Xcode Command Line Tools (`xcode-select --install`)
  - Linux: GCC 7+ or Clang 5+
  - Windows: Visual Studio 2019+ or MinGW, or use `winget install Microsoft.VisualStudio.2022.BuildTools`

- **cpp-httplib** - HTTP server library
  - macOS: `brew install cpp-httplib`
  - Linux: Install from source or package manager
  - Windows: Install via vcpkg or build from source

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

**Windows:**
```cmd
REM Quick dependency check
bin\check-deps

REM Or check manually:
docker --version
docker-compose --version
cmake --version
cl  # or g++ --version
```

## Getting Started

### Option 1: Docker Container (Recommended)

**Quick Start with Docker:**
```bash
# Clone the repository
git clone <repository-url>
cd messaging-service

# Start everything with one command
docker-compose up --build

# Test the service
curl http://localhost:8080/health
curl http://localhost:8080/api/conversations

# Stop the services
docker-compose down
```

**Docker Commands:**
- `docker-compose up --build` - Start all services (database + application)
- `docker-compose up -d --build` - Start in background
- `docker-compose down` - Stop all services
- `docker-compose logs -f` - View logs
- `docker-compose logs -f messaging-service` - View application logs only

### Option 2: Local Development

**macOS/Linux:**
1. Clone the repository
2. Run `make setup` to initialize the project and start PostgreSQL
3. Run `make build` to build the C++ application
4. Run `make run` to start the application
5. Run `make test` to run tests
6. Run `make stop` to stop the application

**Windows:**
1. Clone the repository
2. Run `make.bat setup` to initialize the project and start PostgreSQL
3. Run `make.bat build` to build the C++ application
4. Run `make.bat run` to start the application
5. Run `make.bat test` to run tests
6. Run `make.bat stop` to stop the application

## Available Commands

The project includes several commands for easy development:

### Docker Commands (Recommended)

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

**Windows (using make.bat):**
- `make.bat check-deps` - Check if all required dependencies are installed
- `make.bat setup` - Initialize project and start PostgreSQL database
- `make.bat build` - Build the C++ application
- `make.bat run` - Start the messaging service on port 8080 (default)
- `make.bat run PORT=3000` - Start the messaging service on a custom port
- `make.bat stop` - Stop the messaging service
- `make.bat test` - Run endpoint tests
- `make.bat clean` - Stop containers and clean up temporary files
- `make.bat db-up` - Start PostgreSQL database only
- `make.bat db-down` - Stop PostgreSQL database only
- `make.bat db-logs` - Show database logs
- `make.bat db-shell` - Connect to database shell
- `make.bat help` - Show all available commands

## Development

### Docker Development (Recommended)

The easiest way to develop is using Docker containers:

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

### Local Development

If you prefer local development:

- Use `make setup` to start PostgreSQL database and initialize the project
- Use `make build` to build the C++ application
- Use `make run` to start the development server (default port 8080)
- Use `make run PORT=3000` to start on a custom port
- Use `make test` to run tests
- Use `make stop` to stop the application
- Use `make clean` to stop containers and clean up

### Port Configuration

The messaging service runs on port 8080 by default, but you can specify a custom port:

**macOS/Linux:**
```bash
# Default port (8080)
make run

# Custom port
make run PORT=3000

# Direct script usage
./bin/start 3000

# Direct executable usage
./build/messaging-service 3000

# Show help for start script
./bin/start --help

# Database inspection
./bin/db-inspect                    # Show all tables and data
./bin/db-inspect --conversations    # Show only conversations
./bin/db-inspect --messages         # Show only messages
./bin/db-inspect --counts           # Show only row counts
./bin/db-inspect --help             # Show all options
```

**Windows:**
```cmd
REM Default port (8080)
make.bat run

REM Custom port
make.bat run PORT=3000

REM Direct script usage
bin\start 3000

REM Direct executable usage
build\Release\messaging-service.exe 3000

REM Show help for start script
bin\start --help

REM Database inspection
bin\db-inspect                    # Show all tables and data
bin\db-inspect --conversations    # Show only conversations
bin\db-inspect --messages         # Show only messages
bin\db-inspect --counts           # Show only row counts
bin\db-inspect --help             # Show all options
```

The application validates that the port is between 1 and 65535 and will show an error message for invalid ports. Both the start script and the C++ executable provide helpful error messages and usage information.

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
