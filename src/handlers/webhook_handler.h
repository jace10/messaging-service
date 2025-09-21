#pragma once

#include <httplib.h>
#include <string>

class WebhookHandler {
public:
    void handleIncomingSms(const httplib::Request& req, httplib::Response& res);
    void handleIncomingEmail(const httplib::Request& req, httplib::Response& res);
    
private:
    void logRequest(const std::string& endpoint, const std::string& body);
};
