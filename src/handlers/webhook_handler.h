#pragma once

#include <httplib.h>
#include <string>

//This class handles incoming messages
class WebhookHandler {
public:
    /**
     * @brief Handle POST request for incoming SMS/MMS webhooks
     * @param req HTTP request object containing incoming SMS/MMS data
     * @param res HTTP response object to populate with webhook processing result
     */
    void handleIncomingSms(const httplib::Request& req, httplib::Response& res);
    
    /**
     * @brief Handle POST request for incoming email webhooks
     * @param req HTTP request object containing incoming email data
     * @param res HTTP response object to populate with webhook processing result
     */
    void handleIncomingEmail(const httplib::Request& req, httplib::Response& res);
    
private:
    /**
     * @brief Log request information to console
     * @param endpoint The endpoint being accessed
     * @param body The request body content to log
     */
    void logRequest(const std::string& endpoint, const std::string& body);
};
