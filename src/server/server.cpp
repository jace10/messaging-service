#include "server.h"
#include "../handlers/message_handler.h"
#include "../handlers/webhook_handler.h"
#include "../handlers/conversation_handler.h"
#include <iostream>
#include <signal.h>

MessagingServer::MessagingServer(int port) : port_(port) {
    server_ = std::make_unique<httplib::Server>();
    setupRoutes();
}

void MessagingServer::start() {
    std::cout << "Starting server on port " << port_ << "..." << std::endl;
    
    // 0.0.0.0 listens on all interfaces
    if (!server_->listen("0.0.0.0", port_)) {
        throw std::runtime_error("Failed to start server on port " + std::to_string(port_));
    }
}

void MessagingServer::stop() {
    if (server_) {
        server_->stop();
    }
}

void MessagingServer::setupRoutes() {
    setupMessageRoutes();
    setupWebhookRoutes();
    setupConversationRoutes();
    
    // Health check endpoint
    server_->Get("/health", [](const httplib::Request&, httplib::Response& res) {
        res.set_content("OK", "text/plain");
    });
}

void MessagingServer::setupMessageRoutes() {
    // Send SMS/MMS
    server_->Post("/api/messages/sms", [](const httplib::Request& req, httplib::Response& res) {
        MessageHandler handler;
        handler.handleSendSms(req, res);
    });
    
    // Send Email
    server_->Post("/api/messages/email", [](const httplib::Request& req, httplib::Response& res) {
        MessageHandler handler;
        handler.handleSendEmail(req, res);
    });
}

void MessagingServer::setupWebhookRoutes() {
    // Incoming SMS/MMS webhook
    server_->Post("/api/webhooks/sms", [](const httplib::Request& req, httplib::Response& res) {
        WebhookHandler handler;
        handler.handleIncomingSms(req, res);
    });
    
    // Incoming Email webhook
    server_->Post("/api/webhooks/email", [](const httplib::Request& req, httplib::Response& res) {
        WebhookHandler handler;
        handler.handleIncomingEmail(req, res);
    });
}

void MessagingServer::setupConversationRoutes() {
    // Get conversations
    server_->Get("/api/conversations", [](const httplib::Request& req, httplib::Response& res) {
        ConversationHandler handler;
        handler.handleGetConversations(req, res);
    });
    
    // Get messages for a conversation
    server_->Get("/api/conversations/(.*)/messages", [](const httplib::Request& req, httplib::Response& res) {
        ConversationHandler handler;
        handler.handleGetMessages(req, res);
    });
}
