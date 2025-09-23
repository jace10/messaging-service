#include "conversation_handler.h"
#include "../types/status_codes.h"
#include <iostream>

ConversationHandler::ConversationHandler() {
    database_.connect();
}

void ConversationHandler::handleGetConversations(const httplib::Request& req, httplib::Response& res) {
    logRequest("Get Conversations");
    
    try {
        std::string conversations_json = database_.getAllConversations();
        res.status = toInt(StatusCodeType::OK);
        res.set_content(conversations_json, "application/json");
    } catch (const std::exception& e) {
        std::cerr << "Error getting conversations: " << e.what() << std::endl;
        res.status = toInt(StatusCodeType::INTERNAL_SERVER_ERROR);
        res.set_content("{\"conversations\": [], \"error\": \"Internal server error\"}", "application/json");
    }
}

void ConversationHandler::handleGetMessages(const httplib::Request& req, httplib::Response& res) {
    // Extract conversation ID from URL path
    std::string conversationId = req.matches[1];
    logRequest("Get Messages", "conversation_id=" + conversationId);
    
    try {
        // Validate conversation ID
        int conversation_id;
        try {
            conversation_id = std::stoi(conversationId);
        } catch (const std::exception& e) {
            res.status = toInt(StatusCodeType::BAD_REQUEST);
            res.set_content("{\"messages\": [], \"error\": \"Invalid conversation ID\"}", "application/json");
            return;
        }
        
        // Check if conversation exists
        if (!database_.conversationExists(conversation_id)) {
            res.status = toInt(StatusCodeType::NOT_FOUND);
            res.set_content("{\"messages\": [], \"error\": \"Conversation not found\"}", "application/json");
            return;
        }
        
        // Get messages for the conversation
        std::string messages_json = database_.getMessagesForConversation(conversation_id);
        res.status = toInt(StatusCodeType::OK);
        res.set_content(messages_json, "application/json");
        
    } catch (const std::exception& e) {
        std::cerr << "Error getting messages: " << e.what() << std::endl;
        res.status = toInt(StatusCodeType::INTERNAL_SERVER_ERROR);
        res.set_content("{\"messages\": [], \"error\": \"Internal server error\"}", "application/json");
    }
}

void ConversationHandler::logRequest(const std::string& endpoint, const std::string& params) {
    std::cout << "[" << endpoint << "]";
    if (!params.empty()) {
        std::cout << " " << params;
    }
    std::cout << std::endl;
}
