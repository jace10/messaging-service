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
    /**
     * @brief Default constructor for Database class
     */
    Database();
    
    /**
     * @brief Default destructor
     */
    ~Database() = default;
    
    /**
     * @brief Establish connection to the PostgreSQL database
     * @return true if connection successful, false otherwise
     */
    bool connect();
    
    /**
     * @brief Check if database connection is active
     * @return true if connected, false otherwise
     */
    bool isConnected() const;
    
    // Conversation operations
    /**
     * @brief Find existing conversation or create new one between two participants
     * @param participant_from The sender participant identifier
     * @param participant_to The recipient participant identifier
     * @return Conversation ID if successful, -1 if failed
     */
    int findOrCreateConversation(const std::string& participant_from, const std::string& participant_to);
    
    /**
     * @brief Retrieve all conversations from the database
     * @return JSON string containing all conversations data
     */
    std::string getAllConversations();
    
    /**
     * @brief Check if a conversation with the given ID exists
     * @param conversation_id The conversation ID to check
     * @return true if conversation exists, false otherwise
     */
    bool conversationExists(int conversation_id);
    
    /**
     * @brief Get all messages for a specific conversation
     * @param conversation_id The conversation ID to retrieve messages for
     * @return JSON string containing all messages for the conversation
     */
    std::string getMessagesForConversation(int conversation_id);
    
    // Message operations
    // Schema in the database is defined in the init.sql file
    /**
     * @brief Insert a new message into the database
     * @param conversation_id The ID of the conversation this message belongs to
     * @param from_address The sender's address
     * @param to_address The recipient's address
     * @param message_type The type of message (sms, mms, email)
     * @param body The message content/body
     * @param attachments JSON string containing attachment data
     * @param messaging_provider_id The ID of the messaging provider used
     * @param timestamp The timestamp when the message was sent/received
     * @param direction The direction of the message (inbound, outbound)
     * @return true if insertion successful, false otherwise
     */
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
    /**
     * @brief Build database connection string from environment variables
     * @return Connection string for PostgreSQL
     */
    std::string buildConnectionString();
    
    /**
     * @brief Escape special characters in string for safe database insertion
     * @param input The string to escape
     * @return Escaped string safe for database operations
     */
    std::string escapeString(const std::string& input);
};
