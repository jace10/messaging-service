#include "webhook_handler.h"
#include "../database/database.h"
#include "../utils/json_parser.h"
#include <iostream>

void WebhookHandler::handleIncomingSms(const httplib::Request& req, httplib::Response& res) {
    logRequest("Incoming SMS Webhook", req.body);
    
    try {
        // Parse JSON request body
        auto json_data = JsonParser::parse(req.body);
        
        // Validate required fields
        std::string from = json_data["from"];
        std::string to = json_data["to"];
        std::string type = json_data["type"];
        std::string messaging_provider_id = json_data["messaging_provider_id"];
        std::string body = json_data["body"];
        std::string timestamp = json_data["timestamp"];
        std::string attachments = json_data.count("attachments") ? json_data["attachments"] : "null";
        
        if (from.empty() || to.empty() || type.empty() || messaging_provider_id.empty() || 
            body.empty() || timestamp.empty()) {
            res.status = 400;
            res.set_content("{\"status\": \"error\", \"message\": \"Missing required fields\"}", "application/json");
            return;
        }
        
        // Validate message type
        if (type != "sms" && type != "mms") {
            res.status = 400;
            res.set_content("{\"status\": \"error\", \"message\": \"Invalid message type\"}", "application/json");
            return;
        }
        
        // Connect to database
        Database db;
        if (!db.connect()) {
            res.status = 500;
            res.set_content("{\"status\": \"error\", \"message\": \"Database connection failed\"}", "application/json");
            return;
        }
        
        // Find or create conversation
        int conversation_id = db.findOrCreateConversation(from, to);
        if (conversation_id == -1) {
            res.status = 500;
            res.set_content("{\"status\": \"error\", \"message\": \"Failed to find or create conversation\"}", "application/json");
            return;
        }
        
        // Store message in database
        bool success = db.insertMessage(
            conversation_id,
            from,
            to,
            type,
            body,
            attachments,
            messaging_provider_id,
            timestamp,
            "inbound"
        );
        
        if (!success) {
            res.status = 500;
            res.set_content("{\"status\": \"error\", \"message\": \"Failed to store message\"}", "application/json");
            return;
        }
        
        res.status = 200;
        res.set_content("{\"status\": \"success\", \"message\": \"SMS webhook processed\", \"conversation_id\": " + std::to_string(conversation_id) + "}", "application/json");
        
    } catch (const std::exception& e) {
        std::cerr << "Error processing SMS webhook: " << e.what() << std::endl;
        res.status = 500;
        res.set_content("{\"status\": \"error\", \"message\": \"Internal server error\"}", "application/json");
    }
}

void WebhookHandler::handleIncomingEmail(const httplib::Request& req, httplib::Response& res) {
    logRequest("Incoming Email Webhook", req.body);
    
    // TODO: Implement incoming Email processing
    // Parse JSON request body
    // Validate required fields (from, to, xillio_id, body, timestamp)
    // Store message in database
    // Update conversation
    // Return appropriate response
    
    res.status = 200;
    res.set_content("{\"status\": \"success\", \"message\": \"Email webhook processed\"}", "application/json");
}

void WebhookHandler::logRequest(const std::string& endpoint, const std::string& body) {
    std::cout << "[" << endpoint << "] Received webhook: " << body << std::endl;
}
