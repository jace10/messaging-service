cmake_minimum_required(VERSION 3.16)
project(messaging-service)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Include directories for httplib
include_directories(/usr/local/include)

# Source files
set(SOURCES
    src/main.cpp
    src/server/server.cpp
    src/handlers/message_handler.cpp
    src/handlers/webhook_handler.cpp
    src/handlers/conversation_handler.cpp
    src/database/database.cpp
    src/utils/json_parser.cpp
    src/utils/worker_pool.cpp
    src/providers/messaging_provider.cpp
    src/providers/implementations/DefaultMessagingProvider.cpp
)

# Create executable
add_executable(messaging-service ${SOURCES})

# Find required packages
find_package(Threads REQUIRED)

# Find PostgreSQL - try pkg-config first, then manual search
find_package(PkgConfig QUIET)
if(PkgConfig_FOUND)
    pkg_check_modules(POSTGRESQL libpq)
    if(POSTGRESQL_FOUND)
        message(STATUS "Found PostgreSQL via pkg-config")
        include_directories(${POSTGRESQL_INCLUDE_DIRS})
        target_link_libraries(messaging-service ${POSTGRESQL_LIBRARIES})
    endif()
endif()

# If pkg-config didn't work, try manual search
if(NOT POSTGRESQL_FOUND)
    find_path(POSTGRESQL_INCLUDE_DIR libpq-fe.h
        PATHS /opt/homebrew/include/postgresql@14 /opt/homebrew/include /usr/include /usr/local/include /usr/include/postgresql
    )

    find_library(POSTGRESQL_LIBRARY pq
        PATHS /opt/homebrew/lib/postgresql@14 /opt/homebrew/lib /usr/lib /usr/local/lib /usr/lib/x86_64-linux-gnu
    )

    if(POSTGRESQL_INCLUDE_DIR AND POSTGRESQL_LIBRARY)
        message(STATUS "Found PostgreSQL: ${POSTGRESQL_LIBRARY}")
        include_directories(${POSTGRESQL_INCLUDE_DIR})
        target_link_libraries(messaging-service ${POSTGRESQL_LIBRARY})
    else()
        message(FATAL_ERROR "PostgreSQL not found")
    endif()
endif()

# Link libraries
target_link_libraries(messaging-service 
    Threads::Threads
)

# Unit Tests
enable_testing()

# Test sources
set(TEST_SOURCES
    tests/test_runner.cpp
    tests/test_json_parser.cpp
    src/utils/json_parser.cpp
)

# Create test executable
add_executable(messaging-service-tests ${TEST_SOURCES})

# Include directories for tests
target_include_directories(messaging-service-tests PRIVATE 
    src
    tests
)

# Link test executable with required libraries
target_link_libraries(messaging-service-tests 
    Threads::Threads
)

# Add test to CTest
add_test(NAME messaging-service-tests COMMAND messaging-service-tests)
