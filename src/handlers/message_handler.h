#pragma once

#include <httplib.h>
#include <string>

//This class handles sending messages
class MessageHandler {
public:
    /**
     * @brief Handle POST request to send SMS/MMS messages
     * @param req HTTP request object containing SMS/MMS data in JSON body
     * @param res HTTP response object to populate with send result
     */
    void handleSendSms(const httplib::Request& req, httplib::Response& res);
    
    /**
     * @brief Handle POST request to send email messages
     * @param req HTTP request object containing email data in JSON body
     * @param res HTTP response object to populate with send result
     */
    void handleSendEmail(const httplib::Request& req, httplib::Response& res);
    
private:
    /**
     * @brief Log request information to console
     * @param endpoint The endpoint being accessed
     * @param body The request body content to log
     */
    void logRequest(const std::string& endpoint, const std::string& body);
};
