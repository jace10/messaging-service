#pragma once

#include <httplib.h>
#include <memory>
#include <string>
#include "../handlers/message_handler.h"

//This is the class containing the server functions. 
class MessagingServer {
private:
    //locally owned allocated smart pointer to an instance
    std::unique_ptr<httplib::Server> server_;
    int port_;
    
    // Shared message handler instance with worker pool
    std::unique_ptr<MessageHandler> messageHandler_;
    
public:
    /**
     * @brief Constructor for MessagingServer
     * @param port The port number to listen on (default 8080)
     */
    MessagingServer(int port = 8080);
    
    /**
     * @brief Default destructor
     */
    ~MessagingServer() = default;
    
    /**
     * @brief Start the HTTP server and begin listening for requests
     */
    void start();
    
    /**
     * @brief Stop the HTTP server
     */
    void stop();
    
private:
    /**
     * @brief Set up all HTTP routes and endpoints
     */
    void setupRoutes();
    
    /**
     * @brief Set up message-related routes (SMS, Email sending)
     */
    void setupMessageRoutes();
    
    /**
     * @brief Set up webhook routes for incoming messages
     */
    void setupWebhookRoutes();
    
    /**
     * @brief Set up conversation-related routes (get conversations, get messages)
     */
    void setupConversationRoutes();
};
