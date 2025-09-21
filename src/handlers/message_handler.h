#pragma once

#include <httplib.h>
#include <string>

//This class handles sending messages
class MessageHandler {
public:
    void handleSendSms(const httplib::Request& req, httplib::Response& res);
    void handleSendEmail(const httplib::Request& req, httplib::Response& res);
    
private:
    void logRequest(const std::string& endpoint, const std::string& body);
};
