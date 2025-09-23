# Unit Tests

This directory contains unit tests for the messaging service using a custom C++ test framework.

## Test Framework

The test framework is implemented in `test_framework.h` and provides:

- Simple test registration and execution
- Assertion macros for common test cases
- Clear pass/fail reporting
- Exception handling

### Available Assertions

- `ASSERT_TRUE(condition)` - Asserts that a condition is true
- `ASSERT_FALSE(condition)` - Asserts that a condition is false  
- `ASSERT_EQUAL(expected, actual)` - Asserts that two values are equal
- `ASSERT_NOT_EQUAL(not_expected, actual)` - Asserts that two values are not equal

### Test Structure

Tests are organized by class/component in separate files:

- `test_json_parser.cpp` - Tests for JsonParser class
- `test_runner.cpp` - Main test runner that executes all test suites

## Building and Running Tests

### Build Tests
```bash
cd build
cmake ..
make messaging-service-tests
```

### Run Tests
```bash
# Direct execution
./messaging-service-tests

# Using CTest
ctest
```

## Adding New Tests

1. Create a new test file in the `tests/` directory (e.g., `test_database.cpp`)
2. Include the test framework header: `#include "test_framework.h"`
3. Create a test function that takes a `TestFramework&` parameter
4. Use the `TEST()` macro to define individual test cases
5. Add your test function to `test_runner.cpp`

### Example Test

```cpp
#include "test_framework.h"
#include "../src/your_class.h"

void runYourClassTests(TestFramework& framework) {
    TEST("YourClass::method - basic functionality") {
        YourClass obj;
        bool result = obj.method();
        ASSERT_TRUE(result);
        return true;
    });
}
```

## Current Test Coverage

- **JsonParser::trim** - 10 test cases covering various whitespace scenarios
  - Empty strings
  - Leading/trailing whitespace
  - Mixed whitespace characters
  - JSON-like strings
  - Edge cases

## Test Results

All tests should pass. If any test fails, the framework will provide detailed information about the assertion that failed, including the line number and expected vs actual values.
