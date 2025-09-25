# Scripts Directory

This directory contains scripts for Unix-like systems (Linux, macOS).

## Structure

- **Root level**: Wrapper scripts that delegate to Unix-specific implementations
- **`unix/`**: Unix-specific scripts (macOS/Linux) - `.sh` files

## Usage

Use the wrapper scripts in the root directory:

```bash
# Check dependencies
./bin/check-deps

# Start the service
./bin/start --help

# Stop the service
./bin/stop

# Run tests
./bin/test

# Database operations
./bin/db-clear
./bin/db-inspect
```

### Platform-Specific
You can also call the Unix scripts directly:

```bash
# Unix
./bin/unix/check-deps.sh
./bin/unix/start.sh --help
```

## Scripts

- **`start`** - Start the messaging service (with optional port parameter)
- **`stop`** - Stop the messaging service
- **`test`** - Run API endpoint tests
- **`check-deps`** - Check if all required dependencies are installed
- **`db-clear`** - Clear the database
- **`db-inspect`** - Inspect database contents

## Platform Support

This project supports Unix-like systems:
- **Linux** (all distributions)
- **macOS** (all versions)
- **Other Unix-like systems** (as fallback)
