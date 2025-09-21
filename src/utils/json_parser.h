#pragma once

#include <string>
#include <map>
#include <vector>

class JsonParser {
public:
    static std::map<std::string, std::string> parse(const std::string& json);
    
private:
    static std::string extractValue(const std::string& json, const std::string& key);
    static std::string unescapeJsonString(const std::string& str);
    static void trim(std::string& str);
};
