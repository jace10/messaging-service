#pragma once

#include <string>
#include <map>
#include <vector>

class JsonParser {
public:
    /**
     * @brief Parse a JSON string into a map of key-value pairs
     * @param json The JSON string to parse
     * @return Map containing parsed key-value pairs
     */
    static std::map<std::string, std::string> parse(const std::string& json);
    
    /**
     * @brief Remove leading and trailing whitespace from string
     * @param str The string to trim (modified in place)
     */
    static void trim(std::string& str);
    
private:
    /**
     * @brief Extract a specific value from JSON string by key
     * @param json The JSON string to search in
     * @param key The key to extract value for
     * @return The value associated with the key, empty string if not found
     */
    static std::string extractValue(const std::string& json, const std::string& key);
    
    /**
     * @brief Unescape JSON string by converting escape sequences to actual characters
     * @param str The string to unescape
     * @return Unescaped string
     */
    static std::string unescapeJsonString(const std::string& str);
};
