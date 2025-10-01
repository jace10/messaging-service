#include "message_handler.h"
#include "../database/database.h"
#include "../utils/json_parser.h"
#include "../utils/message_scheduler.h"
#include "../types/status_codes.h"
#include "../providers/messaging_provider.h"
#include <iostream>
#include <vector>
#include <chrono>
#include <iomanip>
#include <sstream>
#include <thread>
#include <ctime>

using namespace messaging_service;

MessageHandler::MessageHandler() 
    : workerPool_(std::make_unique<WorkerPool>(10)),
      messageScheduler_(std::make_unique<MessageScheduler>(workerPool_.get())) {
    std::cout << "[MESSAGE HANDLER] Initialized with worker pool" << std::endl;
    messageScheduler_->start();
    std::cout << "[MESSAGE HANDLER] Started message scheduler" << std::endl;
}

MessageHandler::~MessageHandler() {
    if (messageScheduler_) {
        messageScheduler_->stop();
    }
    if (workerPool_) {
        workerPool_->stop();
    }
}

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
        std::string send_time = json_data.count("send_time") ? json_data["send_time"] : "null";
        
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
        
        // Get the appropriate provider based on message type
        auto provider = MessagingProviderFactory::getProviderForType(type);
        if (!provider) {
            res.status = toInt(StatusCodeType::INTERNAL_SERVER_ERROR);
            res.set_content("{\"status\": \"error\", \"message\": \"No provider configured for message type: " + type + "\"}", "application/json");
            return;
        }
        
        std::cout << "[MESSAGE HANDLER] Using provider: " << provider->getProviderName() << " for message type: " << type << std::endl;
        
        // Create message request
        MessageRequest messageRequest(from, to, type, body, provider->getProviderName(), timestamp, "outbound");
        
        // Parse attachments if provided
        if (attachments != "null" && !attachments.empty()) {
            // Simple parsing - in real implementation, this would be more sophisticated
            if (attachments.find('[') != std::string::npos) {
                // Handle JSON array format
                messageRequest.attachments = {attachments}; // Simplified for now
            } else {
                messageRequest.attachments = {attachments};
            }
        }
        
        // Send message through provider using worker pool
        std::cout << "[MESSAGE HANDLER] Submitting sendMessage task to worker pool" << std::endl;
        auto future = workerPool_->submit([provider, messageRequest]() {
            return provider->sendMessage(messageRequest);
        });
        
        // Wait for the result
        MessageResponse providerResponse = future.get();
        
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
        
        // Check if this is a scheduled message
        bool isScheduled = (send_time != "null" && !send_time.empty());
        
        if (isScheduled) {
            // For scheduled messages, store with sent_time=NULL and schedule for later
            int message_id = db.insertMessage(
                conversation_id,
                from,
                to,
                type,
                body,
                attachments,
                providerResponse.provider_message_id,
                timestamp,
                "outbound",
                "" // sent_time is NULL for scheduled messages
            );
            
            if (message_id == -1) {
                res.status = toInt(StatusCodeType::INTERNAL_SERVER_ERROR);
                res.set_content("{\"status\": \"error\", \"message\": \"Failed to store scheduled message\"}", "application/json");
                return;
            }
            
            // Schedule the message for future sending using the new scheduler
            messageScheduler_->scheduleMessage(
                message_id,
                conversation_id,
                from,
                to,
                type,
                body,
                attachments,
                providerResponse.provider_message_id,
                timestamp,
                send_time,
                provider
            );
            
            res.status = toInt(StatusCodeType::OK);
            res.set_content("{\"status\": \"success\", \"message\": \"Message scheduled for delivery\", \"conversation_id\": " + std::to_string(conversation_id) + ", \"message_id\": " + std::to_string(message_id) + ", \"scheduled_time\": \"" + send_time + "\"}", "application/json");
        } else {
            // For immediate messages, store with sent_time and return provider response
            std::string currentTime = getCurrentTimestamp();
            int message_id = db.insertMessage(
                conversation_id,
                from,
                to,
                type,
                body,
                attachments,
                providerResponse.provider_message_id,
                timestamp,
                "outbound",
                currentTime // sent_time is set to current time for immediate messages
            );
            
            if (message_id == -1) {
                res.status = toInt(StatusCodeType::INTERNAL_SERVER_ERROR);
                res.set_content("{\"status\": \"error\", \"message\": \"Failed to store message\"}", "application/json");
                return;
            }
            
            // Return response based on provider result
            if (providerResponse.success) {
                res.status = toInt(StatusCodeType::OK);
                res.set_content("{\"status\": \"success\", \"message\": \"" + providerResponse.message + "\", \"conversation_id\": " + std::to_string(conversation_id) + ", \"message_id\": " + std::to_string(message_id) + ", \"provider_message_id\": \"" + providerResponse.provider_message_id + "\"}", "application/json");
            } else {
                res.status = providerResponse.http_status_code;
                res.set_content("{\"status\": \"error\", \"message\": \"" + providerResponse.message + "\", \"error_code\": \"" + providerResponse.error_code + "\"}", "application/json");
            }
        }
        
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
        std::string type = json_data["type"];
        std::string body = json_data["body"];
        std::string timestamp = json_data["timestamp"];
        std::string subject = json_data.count("subject") ? json_data["subject"] : "";
        std::string attachments = json_data.count("attachments") ? json_data["attachments"] : "null";
        std::string send_time = json_data.count("send_time") ? json_data["send_time"] : "null";
        
        // Validate required fields
        if (from.empty() || to.empty() || type.empty() || 
            body.empty() || timestamp.empty()) {
            res.status = toInt(StatusCodeType::BAD_REQUEST);
            res.set_content("{\"status\": \"error\", \"message\": \"Missing required fields\"}", "application/json");
            return;
        }
        
        // Validate message type
        if (type != "email") {
            res.status = toInt(StatusCodeType::BAD_REQUEST);
            res.set_content("{\"status\": \"error\", \"message\": \"Invalid message type\"}", "application/json");
            return;
        }
        
        // Get the appropriate provider based on message type
        auto provider = MessagingProviderFactory::getProviderForType(type);
        if (!provider) {
            res.status = toInt(StatusCodeType::INTERNAL_SERVER_ERROR);
            res.set_content("{\"status\": \"error\", \"message\": \"No provider configured for message type: " + type + "\"}", "application/json");
            return;
        }
        
        std::cout << "[MESSAGE HANDLER] Using provider: " << provider->getProviderName() << " for message type: " << type << std::endl;
        
        // Create message request
        MessageRequest messageRequest(from, to, type, body, provider->getProviderName(), timestamp, "outbound");
        messageRequest.subject = subject;
        
        // Parse attachments if provided
        if (attachments != "null" && !attachments.empty()) {
            // Simple parsing - in real implementation, this would be more sophisticated
            if (attachments.find('[') != std::string::npos) {
                // Handle JSON array format
                messageRequest.attachments = {attachments}; // Simplified for now
            } else {
                messageRequest.attachments = {attachments};
            }
        }
        
        // Send message through provider using worker pool
        std::cout << "[MESSAGE HANDLER] Submitting sendMessage task to worker pool" << std::endl;
        auto future = workerPool_->submit([provider, messageRequest]() {
            return provider->sendMessage(messageRequest);
        });
        
        // Wait for the result
        MessageResponse providerResponse = future.get();
        
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
        
        // For email messages, always send immediately (no scheduling support yet)
        std::string currentTime = getCurrentTimestamp();
        int message_id = db.insertMessage(
            conversation_id,
            from,
            to,
            type,
            body,
            attachments,
            providerResponse.provider_message_id,
            timestamp,
            "outbound",
            currentTime // sent_time is set to current time for immediate messages
        );
        
        if (message_id == -1) {
            res.status = toInt(StatusCodeType::INTERNAL_SERVER_ERROR);
            res.set_content("{\"status\": \"error\", \"message\": \"Failed to store message\"}", "application/json");
            return;
        }
        
        // Return response based on provider result
        if (providerResponse.success) {
            res.status = toInt(StatusCodeType::OK);
            res.set_content("{\"status\": \"success\", \"message\": \"" + providerResponse.message + "\", \"conversation_id\": " + std::to_string(conversation_id) + ", \"message_id\": " + std::to_string(message_id) + ", \"provider_message_id\": \"" + providerResponse.provider_message_id + "\"}", "application/json");
        } else {
            res.status = providerResponse.http_status_code;
            res.set_content("{\"status\": \"error\", \"message\": \"" + providerResponse.message + "\", \"error_code\": \"" + providerResponse.error_code + "\"}", "application/json");
        }
        
    } catch (const std::exception& e) {
        res.status = toInt(StatusCodeType::BAD_REQUEST);
        res.set_content("{\"status\": \"error\", \"message\": \"Invalid JSON or processing error\"}", "application/json");
    }
}

void MessageHandler::logRequest(const std::string& endpoint, const std::string& body) {
    std::cout << "[" << endpoint << "] Received request: " << body << std::endl;
}


std::string MessageHandler::getCurrentTimestamp() {
    auto now = std::chrono::system_clock::now();
    auto time_t = std::chrono::system_clock::to_time_t(now);
    auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(now.time_since_epoch()) % 1000;
    
    std::stringstream ss;
    ss << std::put_time(std::gmtime(&time_t), "%Y-%m-%dT%H:%M:%S");
    ss << '.' << std::setfill('0') << std::setw(3) << ms.count() << 'Z';
    return ss.str();
}
