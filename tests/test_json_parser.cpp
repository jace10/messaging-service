#include "test_framework.h"
#include "../src/utils/json_parser.h"
#include <string>

/**
 * @brief Test cases for JsonParser class
 */
void runJsonParserTests(TestFramework& framework) {
    
    TEST("JsonParser::trim - empty string") {
        std::string str = "";
        JsonParser::trim(str);
        ASSERT_EQUAL("", str);
        return true;
    });
    
    TEST("JsonParser::trim - string with no whitespace") {
        std::string str = "hello";
        JsonParser::trim(str);
        ASSERT_EQUAL("hello", str);
        return true;
    });
    
    TEST("JsonParser::trim - leading whitespace only") {
        std::string str = "  hello";
        JsonParser::trim(str);
        ASSERT_EQUAL("hello", str);
        return true;
    });
    
    TEST("JsonParser::trim - trailing whitespace only") {
        std::string str = "hello  ";
        JsonParser::trim(str);
        ASSERT_EQUAL("hello", str);
        return true;
    });
    
    TEST("JsonParser::trim - both leading and trailing whitespace") {
        std::string str = "  hello  ";
        JsonParser::trim(str);
        ASSERT_EQUAL("hello", str);
        return true;
    });
    
    TEST("JsonParser::trim - only whitespace") {
        std::string str = "   \t\n\r  ";
        JsonParser::trim(str);
        ASSERT_EQUAL("", str);
        return true;
    });
    
    TEST("JsonParser::trim - mixed whitespace characters") {
        std::string str = "\t\n hello world \r\n\t";
        JsonParser::trim(str);
        ASSERT_EQUAL("hello world", str);
        return true;
    });
    
    TEST("JsonParser::trim - whitespace in middle preserved") {
        std::string str = "  hello world  ";
        JsonParser::trim(str);
        ASSERT_EQUAL("hello world", str);
        return true;
    });
    
    TEST("JsonParser::trim - single character") {
        std::string str = " a ";
        JsonParser::trim(str);
        ASSERT_EQUAL("a", str);
        return true;
    });
    
    TEST("JsonParser::trim - JSON-like string") {
        std::string str = "  {\"key\": \"value\"}  ";
        JsonParser::trim(str);
        ASSERT_EQUAL("{\"key\": \"value\"}", str);
        return true;
    });
}
