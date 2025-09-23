#pragma once

#include <httplib.h>
#include <string>
#include "../database/database.h"

//This class handles conversations
class ConversationHandler {
private:
    Database database_;
    
public:
    ConversationHandler();
    void handleGetConversations(const httplib::Request& req, httplib::Response& res);
    void handleGetMessages(const httplib::Request& req, httplib::Response& res);
    
private:
    void logRequest(const std::string& endpoint, const std::string& params = "");
};
