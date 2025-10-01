#include "database.h"
#include <iostream>
#include <cstdlib>
#include <cstring>

Database::Database() : connection_(nullptr, PQfinish) {
    connection_string_ = buildConnectionString();
}

bool Database::connect() {
    connection_ = std::unique_ptr<PGconn, decltype(&PQfinish)>(PQconnectdb(connection_string_.c_str()), PQfinish);
    
    if (PQstatus(connection_.get()) != CONNECTION_OK) {
        std::cerr << "Database connection failed: " << PQerrorMessage(connection_.get()) << std::endl;
        return false;
    }
    
    std::cout << "Database connected successfully" << std::endl;
    return true;
}

bool Database::isConnected() const {
    return connection_ && PQstatus(connection_.get()) == CONNECTION_OK;
}

int Database::findOrCreateConversation(const std::string& participant_from, const std::string& participant_to) {
    if (!isConnected()) {
        std::cerr << "Database not connected" << std::endl;
        return -1;
    }
    
    // First, try to find existing conversation
    std::string select_query = "SELECT id FROM conversations WHERE (participant_from = $1 AND participant_to = $2) OR (participant_from = $2 AND participant_to = $1)";
    const char* param_values[] = {participant_from.c_str(), participant_to.c_str()};
    int param_lengths[] = {static_cast<int>(participant_from.length()), static_cast<int>(participant_to.length())};
    int param_formats[] = {0, 0}; // text format
    
    auto result = std::unique_ptr<PGresult, decltype(&PQclear)>(PQexecParams(connection_.get(), select_query.c_str(), 2, nullptr, param_values, param_lengths, param_formats, 0), PQclear);
    
    if (PQresultStatus(result.get()) == PGRES_TUPLES_OK && PQntuples(result.get()) > 0) {
        return std::atoi(PQgetvalue(result.get(), 0, 0));
    }
    
    // If not found, create new conversation
    std::string insert_query = "INSERT INTO conversations (participant_from, participant_to) VALUES ($1, $2) RETURNING id";
    
    result = std::unique_ptr<PGresult, decltype(&PQclear)>(PQexecParams(connection_.get(), insert_query.c_str(), 2, nullptr, param_values, param_lengths, param_formats, 0), PQclear);
    
    if (PQresultStatus(result.get()) == PGRES_TUPLES_OK && PQntuples(result.get()) > 0) {
        return std::atoi(PQgetvalue(result.get(), 0, 0));
    }
    
    std::cerr << "Failed to find or create conversation: " << PQerrorMessage(connection_.get()) << std::endl;
    return -1;
}

std::string Database::getAllConversations() {
    if (!isConnected()) {
        std::cerr << "Database not connected" << std::endl;
        return "{\"conversations\": [], \"error\": \"Database not connected\"}";
    }
    
    std::string select_query = "SELECT id, participant_from, participant_to, created_at, updated_at FROM conversations ORDER BY created_at DESC";
    
    auto result = std::unique_ptr<PGresult, decltype(&PQclear)>(PQexec(connection_.get(), select_query.c_str()), PQclear);
    
    if (PQresultStatus(result.get()) != PGRES_TUPLES_OK) {
        std::cerr << "Failed to query conversations: " << PQerrorMessage(connection_.get()) << std::endl;
        return "{\"conversations\": [], \"error\": \"Database query failed\"}";
    }
    
    int num_rows = PQntuples(result.get());
    std::string json_response = "{\"conversations\": [";
    
    for (int i = 0; i < num_rows; ++i) {
        if (i > 0) {
            json_response += ",";
        }
        
        std::string id = PQgetvalue(result.get(), i, 0);
        std::string participant_from = PQgetvalue(result.get(), i, 1);
        std::string participant_to = PQgetvalue(result.get(), i, 2);
        std::string created_at = PQgetvalue(result.get(), i, 3);
        std::string updated_at = PQgetvalue(result.get(), i, 4);
        
        json_response += "{";
        json_response += "\"id\":" + id + ",";
        json_response += "\"participant_from\":\"" + participant_from + "\",";
        json_response += "\"participant_to\":\"" + participant_to + "\",";
        json_response += "\"created_at\":\"" + created_at + "\",";
        json_response += "\"updated_at\":\"" + updated_at + "\"";
        json_response += "}";
    }
    
    json_response += "]}";
    return json_response;
}

bool Database::conversationExists(int conversation_id) {
    if (!isConnected()) {
        std::cerr << "Database not connected" << std::endl;
        return false;
    }
    
    std::string select_query = "SELECT id FROM conversations WHERE id = $1";
    std::string conversation_id_str = std::to_string(conversation_id);
    const char* param_values[] = {conversation_id_str.c_str()};
    int param_lengths[] = {static_cast<int>(conversation_id_str.length())};
    int param_formats[] = {0}; // text format
    
    auto result = std::unique_ptr<PGresult, decltype(&PQclear)>(PQexecParams(connection_.get(), select_query.c_str(), 1, nullptr, param_values, param_lengths, param_formats, 0), PQclear);
    
    if (PQresultStatus(result.get()) == PGRES_TUPLES_OK && PQntuples(result.get()) > 0) {
        return true;
    }
    
    return false;
}

std::string Database::getMessagesForConversation(int conversation_id) {
    if (!isConnected()) {
        std::cerr << "Database not connected" << std::endl;
        return "{\"messages\": [], \"error\": \"Database not connected\"}";
    }
    
    std::string select_query = R"(
        SELECT id, conversation_id, from_address, to_address, message_type, body, 
               attachments, messaging_provider_id, timestamp, sent_time, created_at, direction
        FROM messages 
        WHERE conversation_id = $1 
        ORDER BY timestamp ASC
    )";
    
    std::string conversation_id_str = std::to_string(conversation_id);
    const char* param_values[] = {conversation_id_str.c_str()};
    int param_lengths[] = {static_cast<int>(conversation_id_str.length())};
    int param_formats[] = {0}; // text format
    
    auto result = std::unique_ptr<PGresult, decltype(&PQclear)>(PQexecParams(connection_.get(), select_query.c_str(), 1, nullptr, param_values, param_lengths, param_formats, 0), PQclear);
    
    if (PQresultStatus(result.get()) != PGRES_TUPLES_OK) {
        std::cerr << "Failed to query messages: " << PQerrorMessage(connection_.get()) << std::endl;
        return "{\"messages\": [], \"error\": \"Database query failed\"}";
    }
    
    int num_rows = PQntuples(result.get());
    std::string json_response = "{\"messages\": [";
    
    for (int i = 0; i < num_rows; ++i) {
        if (i > 0) {
            json_response += ",";
        }
        
        std::string id = PQgetvalue(result.get(), i, 0);
        std::string conversation_id_db = PQgetvalue(result.get(), i, 1);
        std::string from_address = PQgetvalue(result.get(), i, 2);
        std::string to_address = PQgetvalue(result.get(), i, 3);
        std::string message_type = PQgetvalue(result.get(), i, 4);
        std::string body = PQgetvalue(result.get(), i, 5);
        std::string attachments = PQgetvalue(result.get(), i, 6);
        std::string messaging_provider_id = PQgetvalue(result.get(), i, 7);
        std::string timestamp = PQgetvalue(result.get(), i, 8);
        std::string sent_time = PQgetvalue(result.get(), i, 9);
        std::string created_at = PQgetvalue(result.get(), i, 10);
        std::string direction = PQgetvalue(result.get(), i, 11);
        
        json_response += "{";
        json_response += "\"id\":" + id + ",";
        json_response += "\"conversation_id\":" + conversation_id_db + ",";
        json_response += "\"from_address\":\"" + from_address + "\",";
        json_response += "\"to_address\":\"" + to_address + "\",";
        json_response += "\"message_type\":\"" + message_type + "\",";
        json_response += "\"body\":\"" + body + "\",";
        json_response += "\"attachments\":" + attachments + ",";
        json_response += "\"messaging_provider_id\":\"" + messaging_provider_id + "\",";
        json_response += "\"timestamp\":\"" + timestamp + "\",";
        json_response += "\"sent_time\":\"" + sent_time + "\",";
        json_response += "\"created_at\":\"" + created_at + "\",";
        json_response += "\"direction\":\"" + direction + "\"";
        json_response += "}";
    }
    
    json_response += "]}";
    return json_response;
}

int Database::insertMessage(int conversation_id, 
                           const std::string& from_address,
                           const std::string& to_address,
                           const std::string& message_type,
                           const std::string& body,
                           const std::string& attachments,
                           const std::string& messaging_provider_id,
                           const std::string& timestamp,
                           const std::string& direction,
                           const std::string& sent_time) {
    if (!isConnected()) {
        std::cerr << "Database not connected" << std::endl;
        return -1;
    }
    
    std::string insert_query = R"(
        INSERT INTO messages (conversation_id, from_address, to_address, message_type, body, attachments, messaging_provider_id, timestamp, direction, sent_time)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
        RETURNING id
    )";
    
    std::string conversation_id_str = std::to_string(conversation_id);
    const char* param_values[] = {
        conversation_id_str.c_str(),
        from_address.c_str(),
        to_address.c_str(),
        message_type.c_str(),
        body.c_str(),
        attachments.c_str(),
        messaging_provider_id.c_str(),
        timestamp.c_str(),
        direction.c_str(),
        sent_time.empty() ? nullptr : sent_time.c_str() // Use nullptr for empty string to represent NULL
    };
    
    int param_lengths[] = {
        static_cast<int>(conversation_id_str.length()),
        static_cast<int>(from_address.length()),
        static_cast<int>(to_address.length()),
        static_cast<int>(message_type.length()),
        static_cast<int>(body.length()),
        static_cast<int>(attachments.length()),
        static_cast<int>(messaging_provider_id.length()),
        static_cast<int>(timestamp.length()),
        static_cast<int>(direction.length()),
        sent_time.empty() ? 0 : static_cast<int>(sent_time.length()) // 0 length for NULL
    };
    
    int param_formats[] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0}; // all text format
    
    auto result = std::unique_ptr<PGresult, decltype(&PQclear)>(PQexecParams(connection_.get(), insert_query.c_str(), 10, nullptr, param_values, param_lengths, param_formats, 0), PQclear);
    
    if (PQresultStatus(result.get()) == PGRES_TUPLES_OK) {
        // Get the returned message ID
        char* id_str = PQgetvalue(result.get(), 0, 0);
        return std::atoi(id_str);
    }
    
    std::cerr << "Failed to insert message: " << PQerrorMessage(connection_.get()) << std::endl;
    return -1;
}

bool Database::updateMessageSentTime(int message_id, const std::string& sent_time) {
    if (!isConnected()) {
        std::cerr << "Database not connected" << std::endl;
        return false;
    }
    
    std::string update_query = "UPDATE messages SET sent_time = $1 WHERE id = $2";
    
    std::string message_id_str = std::to_string(message_id);
    const char* param_values[] = {
        sent_time.c_str(),
        message_id_str.c_str()
    };
    
    int param_lengths[] = {
        static_cast<int>(sent_time.length()),
        static_cast<int>(message_id_str.length())
    };
    
    int param_formats[] = {0, 0}; // all text format
    
    auto result = std::unique_ptr<PGresult, decltype(&PQclear)>(PQexecParams(connection_.get(), update_query.c_str(), 2, nullptr, param_values, param_lengths, param_formats, 0), PQclear);
    
    if (PQresultStatus(result.get()) == PGRES_COMMAND_OK) {
        return true;
    }
    
    std::cerr << "Failed to update message sent_time: " << PQerrorMessage(connection_.get()) << std::endl;
    return false;
}

std::string Database::buildConnectionString() {
    std::string host = std::getenv("DB_HOST") ? std::getenv("DB_HOST") : "localhost";
    std::string port = std::getenv("DB_PORT") ? std::getenv("DB_PORT") : "5432";
    std::string dbname = std::getenv("DB_NAME") ? std::getenv("DB_NAME") : "messaging_service";
    std::string user = std::getenv("DB_USER") ? std::getenv("DB_USER") : "messaging_user";
    std::string password = std::getenv("DB_PASSWORD") ? std::getenv("DB_PASSWORD") : "messaging_password";
    
    return "host=" + host + " port=" + port + " dbname=" + dbname + " user=" + user + " password=" + password;
}

std::string Database::escapeString(const std::string& input) {
    if (!isConnected()) {
        return input;
    }
    
    char* escaped = PQescapeLiteral(connection_.get(), input.c_str(), input.length());
    if (!escaped) {
        std::cerr << "Failed to escape string: " << PQerrorMessage(connection_.get()) << std::endl;
        return input;
    }
    
    std::string result(escaped);
    PQfreemem(escaped);
    return result;
}
