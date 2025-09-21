#pragma once

#include <httplib.h>
#include <memory>
#include <string>

class MessagingServer {
private:
    std::unique_ptr<httplib::Server> server_;
    int port_;
    
public:
    MessagingServer(int port = 8080);
    ~MessagingServer() = default;
    
    void start();
    void stop();
    
private:
    void setupRoutes();
    void setupMessageRoutes();
    void setupWebhookRoutes();
    void setupConversationRoutes();
};
