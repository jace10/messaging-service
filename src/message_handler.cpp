#include "message_handler.h"
#include <iostream>

void MessageHandler::handleSendSms(const httplib::Request& req, httplib::Response& res) {
    logRequest("Send SMS", req.body);
    
    // TODO: Implement SMS sending logic
    // Parse JSON request body
    // Validate required fields (from, to, type, body, timestamp)
    // Process the message
    // Return appropriate response
    
    res.status = 200;
    res.set_content("{\"status\": \"success\", \"message\": \"SMS queued for sending\"}", "application/json");
}

void MessageHandler::handleSendEmail(const httplib::Request& req, httplib::Response& res) {
    logRequest("Send Email", req.body);
    
    // TODO: Implement Email sending logic
    // Parse JSON request body
    // Validate required fields (from, to, body, timestamp)
    // Process the email
    // Return appropriate response
    
    res.status = 200;
    res.set_content("{\"status\": \"success\", \"message\": \"Email queued for sending\"}", "application/json");
}

void MessageHandler::logRequest(const std::string& endpoint, const std::string& body) {
    std::cout << "[" << endpoint << "] Received request: " << body << std::endl;
}
