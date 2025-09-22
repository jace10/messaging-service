#pragma once

#include <string>
#include <memory>
#include <libpq-fe.h>

// Class to interact with Postgres database 
class Database {
private:
    std::unique_ptr<PGconn, decltype(&PQfinish)> connection_;
    std::string connection_string_;
    
public:
    Database();
    ~Database() = default;
    
    bool connect();
    bool isConnected() const;
    
    // Conversation operations
    int findOrCreateConversation(const std::string& participant_from, const std::string& participant_to);
    
    // Message operations
    // Schema in the database is defined in the init.sql file
    bool insertMessage(int conversation_id, 
                      const std::string& from_address,
                      const std::string& to_address,
                      const std::string& message_type,
                      const std::string& body,
                      const std::string& attachments,
                      const std::string& messaging_provider_id,
                      const std::string& timestamp,
                      const std::string& direction);
    
private:
    std::string buildConnectionString();
    std::string escapeString(const std::string& input);
};
