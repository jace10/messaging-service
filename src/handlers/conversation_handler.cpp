#include "conversation_handler.h"
#include <iostream>

void ConversationHandler::handleGetConversations(const httplib::Request& req, httplib::Response& res) {
    logRequest("Get Conversations");
    
    // TODO: Implement get conversations logic
    // Query database for all conversations
    // Return JSON list of conversations
    
    res.status = 200;
    res.set_content("{\"conversations\": []}", "application/json");
}

void ConversationHandler::handleGetMessages(const httplib::Request& req, httplib::Response& res) {
    // Extract conversation ID from URL path
    std::string conversationId = req.matches[1];
    logRequest("Get Messages", "conversation_id=" + conversationId);
    
    // TODO: Implement get messages logic
    // Query database for messages in the conversation
    // Return JSON list of messages
    
    res.status = 200;
    res.set_content("{\"messages\": []}", "application/json");
}

void ConversationHandler::logRequest(const std::string& endpoint, const std::string& params) {
    std::cout << "[" << endpoint << "]";
    if (!params.empty()) {
        std::cout << " " << params;
    }
    std::cout << std::endl;
}
