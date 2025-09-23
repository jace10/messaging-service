# Scripts Directory

This directory contains platform-specific scripts organized into subdirectories for better maintainability.

## Structure

- **Root level**: Platform-agnostic wrapper scripts that auto-detect the operating system
- **`unix/`**: Unix-specific scripts (macOS/Linux) - `.sh` files
- **`windows/`**: Windows-specific scripts - `.bat` files

## Usage

### Cross-Platform (Recommended)
Use the wrapper scripts in the root directory - they automatically detect your platform:

```bash
# Unix (macOS/Linux)
./bin/check-deps
./bin/start --help

# Windows
bin\check-deps
bin\start --help
```

### Platform-Specific
You can also call the platform-specific scripts directly:

```bash
# Unix
./bin/unix/check-deps.sh
./bin/unix/start.sh --help

# Windows
bin\windows\check-deps.bat
bin\windows\start.bat --help
```

## Scripts

- **`start`** - Start the messaging service (with optional port parameter)
- **`stop`** - Stop the messaging service
- **`test`** - Run API endpoint tests
- **`check-deps`** - Check if all required dependencies are installed

## Platform Detection

The wrapper scripts detect the platform using the `$OSTYPE` environment variable:
- `msys`, `cygwin`, `win32` → Windows
- `darwin*` → macOS
- `linux-gnu*` → Linux
- Default → Unix (for other platforms)
