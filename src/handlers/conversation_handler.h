#pragma once

#include <httplib.h>
#include <string>
#include "../database/database.h"

//This class handles conversations
class ConversationHandler {
private:
    Database database_;
    
public:
    /**
     * @brief Default constructor for ConversationHandler
     * Establishes database connection upon initialization
     */
    ConversationHandler();
    
    /**
     * @brief Handle GET request to retrieve all conversations
     * @param req HTTP request object containing request details
     * @param res HTTP response object to populate with conversation data
     */
    void handleGetConversations(const httplib::Request& req, httplib::Response& res);
    
    /**
     * @brief Handle GET request to retrieve messages for a specific conversation
     * @param req HTTP request object containing conversation ID in URL path
     * @param res HTTP response object to populate with message data
     */
    void handleGetMessages(const httplib::Request& req, httplib::Response& res);
    
private:
    /**
     * @brief Log request information to console
     * @param endpoint The endpoint being accessed
     * @param params Optional parameters to include in log (default empty)
     */
    void logRequest(const std::string& endpoint, const std::string& params = "");
};
