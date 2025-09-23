#include "test_framework.h"
#include <iostream>

// Forward declarations for test functions
void runJsonParserTests(TestFramework& framework);

/**
 * @brief Main test runner
 */
int main() {
    std::cout << "=== Messaging Service Unit Tests ===\n\n";
    
    TestFramework framework;
    
    // Run all test suites
    runJsonParserTests(framework);
    
    // Execute all tests
    bool allPassed = framework.runTests();
    
    std::cout << "\n=== Test Summary ===\n";
    if (allPassed) {
        std::cout << "All tests PASSED! ✓\n";
        return 0;
    } else {
        std::cout << "Some tests FAILED! ✗\n";
        return 1;
    }
}
