#pragma once

#include <iostream>
#include <string>
#include <vector>
#include <functional>

/**
 * @brief Simple C++ unit test framework
 */
class TestFramework {
private:
    std::vector<std::pair<std::string, std::function<bool()>>> tests_;
    int passed_ = 0;
    int failed_ = 0;

public:
    /**
     * @brief Add a test case
     * @param name Test case name
     * @param test_func Function that returns true if test passes, false otherwise
     */
    void addTest(const std::string& name, std::function<bool()> test_func) {
        tests_.emplace_back(name, test_func);
    }

    /**
     * @brief Run all tests
     * @return true if all tests pass, false otherwise
     */
    bool runTests() {
        std::cout << "Running " << tests_.size() << " test(s)...\n\n";
        
        for (const auto& test : tests_) {
            std::cout << "Test: " << test.first << " ... ";
            
            try {
                bool result = test.second();
                if (result) {
                    std::cout << "PASSED\n";
                    passed_++;
                } else {
                    std::cout << "FAILED\n";
                    failed_++;
                }
            } catch (const std::exception& e) {
                std::cout << "FAILED (Exception: " << e.what() << ")\n";
                failed_++;
            } catch (...) {
                std::cout << "FAILED (Unknown exception)\n";
                failed_++;
            }
        }
        
        std::cout << "\nTest Results:\n";
        std::cout << "  Passed: " << passed_ << "\n";
        std::cout << "  Failed: " << failed_ << "\n";
        std::cout << "  Total:  " << (passed_ + failed_) << "\n";
        
        return failed_ == 0;
    }
};

// Macro for easier test definition
#define TEST(name) \
    framework.addTest(name, [&]() -> bool

#define ASSERT_TRUE(condition) \
    if (!(condition)) { \
        std::cout << "\n    Assertion failed: " << #condition << " at line " << __LINE__; \
        return false; \
    }

#define ASSERT_FALSE(condition) \
    if (condition) { \
        std::cout << "\n    Assertion failed: " << #condition << " should be false at line " << __LINE__; \
        return false; \
    }

#define ASSERT_EQUAL(expected, actual) \
    if ((expected) != (actual)) { \
        std::cout << "\n    Assertion failed: expected " << (expected) << ", got " << (actual) << " at line " << __LINE__; \
        return false; \
    }

#define ASSERT_NOT_EQUAL(not_expected, actual) \
    if ((not_expected) == (actual)) { \
        std::cout << "\n    Assertion failed: expected not " << (not_expected) << ", got " << (actual) << " at line " << __LINE__; \
        return false; \
    }
