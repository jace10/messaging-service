#include "message_handler.h"
#include "../database/database.h"
#include "../utils/json_parser.h"
#include "../types/status_codes.h"
#include <iostream>

void MessageHandler::handleSendSms(const httplib::Request& req, httplib::Response& res) {
    logRequest("Send SMS", req.body);
    
    try {
        // Parse JSON request body
        auto json_data = JsonParser::parse(req.body);
        
        // Validate required fields
        std::string from = json_data["from"];
        std::string to = json_data["to"];
        std::string type = json_data["type"];
        std::string body = json_data["body"];
        std::string attachments = json_data.count("attachments") ? json_data["attachments"] : "null";
        std::string timestamp = json_data["timestamp"];
        
        // Validate required fields
        if (from.empty() || to.empty() || type.empty() || body.empty() || timestamp.empty()) {
            res.status = toInt(StatusCodeType::BAD_REQUEST);
            res.set_content("{\"status\": \"error\", \"message\": \"Missing required fields\"}", "application/json");
            return;
        }
        
        // Validate message type
        if (type != "sms" && type != "mms") {
            res.status = toInt(StatusCodeType::BAD_REQUEST);
            res.set_content("{\"status\": \"error\", \"message\": \"Invalid message type\"}", "application/json");
            return;
        }
        
        // Connect to database
        Database db;
        if (!db.connect()) {
            res.status = toInt(StatusCodeType::INTERNAL_SERVER_ERROR);
            res.set_content("{\"status\": \"error\", \"message\": \"Database connection failed\"}", "application/json");
            return;
        }
        
        // Find or create conversation
        int conversation_id = db.findOrCreateConversation(from, to);
        if (conversation_id == -1) {
            res.status = toInt(StatusCodeType::INTERNAL_SERVER_ERROR);
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
            "",
            timestamp,
            "outbound"
        );
        
        if (!success) {
            res.status = toInt(StatusCodeType::INTERNAL_SERVER_ERROR);
            res.set_content("{\"status\": \"error\", \"message\": \"Failed to store message\"}", "application/json");
            return;
        }
        
        // Return success response
        res.status = toInt(StatusCodeType::OK);
        res.set_content("{\"status\": \"success\", \"message\": \"SMS queued for sending\", \"conversation_id\": " + std::to_string(conversation_id) + "}", "application/json");
        
    } catch (const std::exception& e) {
        res.status = toInt(StatusCodeType::BAD_REQUEST);
        res.set_content("{\"status\": \"error\", \"message\": \"Invalid JSON or processing error\"}", "application/json");
    }
}

void MessageHandler::handleSendEmail(const httplib::Request& req, httplib::Response& res) {
    logRequest("Send Email", req.body);
    
    try {
        // Parse JSON request body
        auto json_data = JsonParser::parse(req.body);
        
        // Validate required fields
        std::string from = json_data["from"];
        std::string to = json_data["to"];
        std::string body = json_data["body"];
        std::string timestamp = json_data["timestamp"];
        std::string attachments = json_data.count("attachments") ? json_data["attachments"] : "null";
        
        // Validate required fields
        if (from.empty() || to.empty() || body.empty() || timestamp.empty()) {
            res.status = toInt(StatusCodeType::BAD_REQUEST);
            res.set_content("{\"status\": \"error\", \"message\": \"Missing required fields\"}", "application/json");
            return;
        }
        
        // Connect to database
        Database db;
        if (!db.connect()) {
            res.status = toInt(StatusCodeType::INTERNAL_SERVER_ERROR);
            res.set_content("{\"status\": \"error\", \"message\": \"Database connection failed\"}", "application/json");
            return;
        }
        
        // Find or create conversation
        int conversation_id = db.findOrCreateConversation(from, to);
        if (conversation_id == -1) {
            res.status = toInt(StatusCodeType::INTERNAL_SERVER_ERROR);
            res.set_content("{\"status\": \"error\", \"message\": \"Failed to find or create conversation\"}", "application/json");
            return;
        }
        
        // Store message in database
        bool success = db.insertMessage(
            conversation_id,
            from,
            to,
            "email",
            body,
            attachments,
            "",
            timestamp,
            "outbound"
        );
        
        if (!success) {
            res.status = toInt(StatusCodeType::INTERNAL_SERVER_ERROR);
            res.set_content("{\"status\": \"error\", \"message\": \"Failed to store message\"}", "application/json");
            return;
        }
        
        // Return success response
        res.status = toInt(StatusCodeType::OK);
        res.set_content("{\"status\": \"success\", \"message\": \"Email queued for sending\", \"conversation_id\": " + std::to_string(conversation_id) + "}", "application/json");
        
    } catch (const std::exception& e) {
        res.status = toInt(StatusCodeType::BAD_REQUEST);
        res.set_content("{\"status\": \"error\", \"message\": \"Invalid JSON or processing error\"}", "application/json");
    }
}

void MessageHandler::logRequest(const std::string& endpoint, const std::string& body) {
    std::cout << "[" << endpoint << "] Received request: " << body << std::endl;
}
