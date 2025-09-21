#pragma once

#include <httplib.h>
#include <memory>
#include <string>

//This is the class containing the server functions. 
class MessagingServer {
private:
    //locally owned allocated smart pointer to an instance
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
