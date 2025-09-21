cmake_minimum_required(VERSION 3.16)
project(messaging-service)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Include directories for cpp-httplib
include_directories(/opt/homebrew/include)

# Source files
set(SOURCES
    src/main.cpp
    src/server/server.cpp
    src/handlers/message_handler.cpp
    src/handlers/webhook_handler.cpp
    src/handlers/conversation_handler.cpp
    src/database/database.cpp
    src/utils/json_parser.cpp
)

# Create executable
add_executable(messaging-service ${SOURCES})

# Find required packages
find_package(Threads REQUIRED)

# Find PostgreSQL
find_path(POSTGRESQL_INCLUDE_DIR libpq-fe.h
    PATHS /opt/homebrew/include/postgresql@14 /opt/homebrew/include /usr/include /usr/local/include
)

find_library(POSTGRESQL_LIBRARY pq
    PATHS /opt/homebrew/lib/postgresql@14 /opt/homebrew/lib /usr/lib /usr/local/lib
)

if(POSTGRESQL_INCLUDE_DIR AND POSTGRESQL_LIBRARY)
    message(STATUS "Found PostgreSQL: ${POSTGRESQL_LIBRARY}")
    include_directories(${POSTGRESQL_INCLUDE_DIR})
else()
    message(FATAL_ERROR "PostgreSQL not found")
endif()

# Link libraries
target_link_libraries(messaging-service 
    Threads::Threads
    ${POSTGRESQL_LIBRARY}
)
