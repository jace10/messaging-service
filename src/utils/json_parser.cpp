#include "json_parser.h"
#include <iostream>
#include <sstream>

std::map<std::string, std::string> JsonParser::parse(const std::string& json) {
    std::map<std::string, std::string> result;
    
    // Remove whitespace
    std::string clean_json = json;
    trim(clean_json);
    
    // Remove outer braces
    if (clean_json.front() == '{' && clean_json.back() == '}') {
        clean_json = clean_json.substr(1, clean_json.length() - 2);
    }
    
    // Split by comma, but be careful about commas inside strings
    std::vector<std::string> pairs;
    std::string current_pair;
    bool in_string = false;
    int brace_level = 0;
    
    for (size_t i = 0; i < clean_json.length(); ++i) {
        char c = clean_json[i];
        
        if (c == '"' && (i == 0 || clean_json[i-1] != '\\')) {
            in_string = !in_string;
        } else if (!in_string) {
            if (c == '{' || c == '[') {
                brace_level++;
            } else if (c == '}' || c == ']') {
                brace_level--;
            } else if (c == ',' && brace_level == 0) {
                pairs.push_back(current_pair);
                current_pair.clear();
                continue;
            }
        }
        
        current_pair += c;
    }
    
    if (!current_pair.empty()) {
        pairs.push_back(current_pair);
    }
    
    // Parse each key-value pair
    for (const auto& pair : pairs) {
        size_t colon_pos = pair.find(':');
        if (colon_pos != std::string::npos) {
            std::string key = pair.substr(0, colon_pos);
            std::string value = pair.substr(colon_pos + 1);
            
            trim(key);
            trim(value);
            
            // Remove quotes from key
            if (key.front() == '"' && key.back() == '"') {
                key = key.substr(1, key.length() - 2);
            }
            
            // Remove quotes from value
            if (value.front() == '"' && value.back() == '"') {
                value = value.substr(1, value.length() - 2);
                value = unescapeJsonString(value);
            }
            
            result[key] = value;
        }
    }
    
    return result;
}

std::string JsonParser::extractValue(const std::string& json, const std::string& key) {
    auto parsed = parse(json);
    auto it = parsed.find(key);
    if (it != parsed.end()) {
        return it->second;
    }
    return "";
}

std::string JsonParser::unescapeJsonString(const std::string& str) {
    std::string result;
    for (size_t i = 0; i < str.length(); ++i) {
        if (str[i] == '\\' && i + 1 < str.length()) {
            switch (str[i + 1]) {
                case '"': result += '"'; break;
                case '\\': result += '\\'; break;
                case '/': result += '/'; break;
                case 'b': result += '\b'; break;
                case 'f': result += '\f'; break;
                case 'n': result += '\n'; break;
                case 'r': result += '\r'; break;
                case 't': result += '\t'; break;
                default: result += str[i + 1]; break;
            }
            ++i; // Skip next character
        } else {
            result += str[i];
        }
    }
    return result;
}

void JsonParser::trim(std::string& str) {
    // Remove leading whitespace
    size_t start = str.find_first_not_of(" \t\n\r");
    if (start != std::string::npos) {
        str = str.substr(start);
        
        // Remove trailing whitespace
        size_t end = str.find_last_not_of(" \t\n\r");
        if (end != std::string::npos) {
            str = str.substr(0, end + 1);
        }
    } else {
        // String contains only whitespace, so clear it
        str.clear();
    }
}
