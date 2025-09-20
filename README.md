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
├── bin/                    # Scripts and executables
│   ├── start.sh           # Application startup script (builds and runs C++ app)
│   ├── stop.sh            # Application stop script
│   └── test.sh            # API testing script with curl commands
├── src/                    # C++ source code
│   ├── main.cpp           # Application entry point
│   ├── server.h/.cpp      # HTTP server setup and routing
│   ├── message_handler.h/.cpp  # SMS/Email sending endpoints
│   ├── webhook_handler.h/.cpp  # Incoming webhook endpoints
│   └── conversation_handler.h/.cpp  # Conversation management endpoints
├── build/                  # Build directory (created by CMake)
├── CMakeLists.txt         # CMake build configuration
├── docker-compose.yml      # PostgreSQL database setup
├── Makefile               # Build and development commands
└── README.md              # This file
```

## Prerequisites

Before running this project, ensure you have the following installed on your system:

### Required Software

- **Docker & Docker Compose** - For running PostgreSQL database
  - macOS: Install [Docker Desktop](https://www.docker.com/products/docker-desktop/) or use `brew install colima` for a lightweight alternative
  - Linux: Install Docker and docker-compose
  - Windows: Install [Docker Desktop](https://www.docker.com/products/docker-desktop/)

- **CMake** (version 3.16 or higher) - For building the C++ application
  - macOS: `brew install cmake`
  - Linux: `sudo apt-get install cmake` (Ubuntu/Debian) or `sudo yum install cmake` (RHEL/CentOS)
  - Windows: Download from [cmake.org](https://cmake.org/download/)

- **C++ Compiler** with C++17 support
  - macOS: Xcode Command Line Tools (`xcode-select --install`)
  - Linux: GCC 7+ or Clang 5+
  - Windows: Visual Studio 2019+ or MinGW

- **cpp-httplib** - HTTP server library
  - macOS: `brew install cpp-httplib`
  - Linux: Install from source or package manager
  - Windows: Install via vcpkg or build from source

### Optional Tools

- **Make** - For running build commands (usually pre-installed)
- **curl** - For testing endpoints (usually pre-installed)
- **Git** - For version control (usually pre-installed)

### Verification

You can verify your installation by running:
```bash
# Quick dependency check
./bin/check-deps.sh

# Or check manually:
docker --version
docker-compose --version
cmake --version
g++ --version  # or clang++ --version
pkg-config --modversion cpp-httplib
```

## Getting Started

1. Clone the repository
2. Run `make setup` to initialize the project and start PostgreSQL
3. Run `make build` to build the C++ application
4. Run `make run` to start the application
5. Run `make test` to run tests
6. Run `make stop` to stop the application

## Available Commands

The project includes several Make commands for easy development:

- `make check-deps` - Check if all required dependencies are installed
- `make setup` - Initialize project and start PostgreSQL database
- `make build` - Build the C++ application
- `make run` - Start the messaging service on port 8080
- `make stop` - Stop the messaging service
- `make test` - Run endpoint tests
- `make clean` - Stop containers and clean up temporary files
- `make db-up` - Start PostgreSQL database only
- `make db-down` - Stop PostgreSQL database only
- `make db-logs` - Show database logs
- `make db-shell` - Connect to database shell
- `make help` - Show all available commands

## Development

- Use `make setup` to start PostgreSQL database and initialize the project
- Use `make build` to build the C++ application
- Use `make run` to start the development server
- Use `make test` to run tests
- Use `make stop` to stop the application
- Use `make clean` to stop containers and clean up

## Database

The application uses PostgreSQL as its database. The docker-compose.yml file sets up:
- PostgreSQL 15 with Alpine Linux
- Database: `messaging_service`
- User: `messaging_user`
- Password: `messaging_password`
- Port: `5432` (exposed to host)

To connect to the database directly:
```bash
docker-compose exec postgres psql -U messaging_user -d messaging_service
```

Again, you are welcome to make changes here, as long as they're in the docker-compose.yml
