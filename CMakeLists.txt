cmake_minimum_required(VERSION 3.16)
project(messaging-service)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Include directories for cpp-httplib
include_directories(/opt/homebrew/include)

# Source files
set(SOURCES
    src/main.cpp
    src/server.cpp
    src/message_handler.cpp
    src/webhook_handler.cpp
    src/conversation_handler.cpp
)

# Create executable
add_executable(messaging-service ${SOURCES})

# Link pthread for cpp-httplib
find_package(Threads REQUIRED)
target_link_libraries(messaging-service Threads::Threads)
