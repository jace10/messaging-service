#pragma once

#include <httplib.h>
#include <string>

class ConversationHandler {
public:
    void handleGetConversations(const httplib::Request& req, httplib::Response& res);
    void handleGetMessages(const httplib::Request& req, httplib::Response& res);
    
private:
    void logRequest(const std::string& endpoint, const std::string& params = "");
};
