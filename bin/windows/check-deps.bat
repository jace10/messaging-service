@echo off
setlocal enabledelayedexpansion

echo 🔍 Checking dependencies for messaging-service...
echo.

REM Function to check if command exists
:check_command
set "cmd=%~1"
where "%cmd%" >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ %cmd% - Found
    exit /b 0
) else (
    echo ❌ %cmd% - Not found
    exit /b 1
)

REM Check Docker
echo 🐳 Docker ^& Docker Compose:
call :check_command docker
if %errorlevel% equ 0 (
    docker --version 2>nul | findstr /C:"Docker version" >nul
    if %errorlevel% equ 0 (
        for /f "tokens=*" %%i in ('docker --version 2^>nul') do echo    Version: %%i
    )
)
call :check_command docker-compose
if %errorlevel% equ 0 (
    docker-compose --version 2>nul | findstr /C:"Docker Compose version" >nul
    if %errorlevel% equ 0 (
        for /f "tokens=*" %%i in ('docker-compose --version 2^>nul') do echo    Version: %%i
    )
)
echo.

REM Check CMake
echo 🔨 Build Tools:
call :check_command cmake
if %errorlevel% equ 0 (
    cmake --version 2>nul | findstr /C:"cmake version" >nul
    if %errorlevel% equ 0 (
        for /f "tokens=*" %%i in ('cmake --version 2^>nul ^| findstr /C:"cmake version"') do echo    Version: %%i
    )
)
echo.

REM Check C++ Compiler
echo ⚙️  C++ Compiler:
call :check_command g++
if %errorlevel% equ 0 (
    g++ --version 2>nul | findstr /C:"g++" >nul
    if %errorlevel% equ 0 (
        for /f "tokens=*" %%i in ('g++ --version 2^>nul ^| findstr /C:"g++"') do echo    Version: %%i
    )
) else (
    call :check_command cl
    if %errorlevel% equ 0 (
        cl 2>nul | findstr /C:"Microsoft" >nul
        if %errorlevel% equ 0 (
            for /f "tokens=*" %%i in ('cl 2^>nul ^| findstr /C:"Microsoft"') do echo    Version: %%i
        )
    ) else (
        echo ❌ No C++ compiler found (need g++ or cl)
    )
)
echo.

REM Check optional tools
echo 🔧 Optional Tools:
call :check_command make
call :check_command curl
call :check_command git
echo.

echo 📖 Installation Instructions:
echo.
echo Windows:
echo   Install Docker Desktop from https://docker.com
echo   Install CMake from https://cmake.org/download/
echo   Install Visual Studio 2019+ or MinGW for C++ compiler
echo   Install cpp-httplib via vcpkg or build from source
echo.
echo PowerShell (if available):
echo   winget install Docker.DockerDesktop
echo   winget install Kitware.CMake
echo   winget install Microsoft.VisualStudio.2022.BuildTools
echo.

echo 🚀 Once all dependencies are installed, run:
echo   make setup
echo   make build
echo   make run
echo.

endlocal
