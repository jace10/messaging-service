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
    std::string select_query = "SELECT id FROM conversations WHERE participant_from = $1 AND participant_to = $2";
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

bool Database::insertMessage(int conversation_id, 
                           const std::string& from_address,
                           const std::string& to_address,
                           const std::string& message_type,
                           const std::string& body,
                           const std::string& attachments,
                           const std::string& messaging_provider_id,
                           const std::string& timestamp,
                           const std::string& direction) {
    if (!isConnected()) {
        std::cerr << "Database not connected" << std::endl;
        return false;
    }
    
    std::string insert_query = R"(
        INSERT INTO messages (conversation_id, from_address, to_address, message_type, body, attachments, messaging_provider_id, timestamp, direction)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
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
        direction.c_str()
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
        static_cast<int>(direction.length())
    };
    
    int param_formats[] = {0, 0, 0, 0, 0, 0, 0, 0, 0}; // all text format
    
    auto result = std::unique_ptr<PGresult, decltype(&PQclear)>(PQexecParams(connection_.get(), insert_query.c_str(), 9, nullptr, param_values, param_lengths, param_formats, 0), PQclear);
    
    if (PQresultStatus(result.get()) == PGRES_COMMAND_OK) {
        return true;
    }
    
    std::cerr << "Failed to insert message: " << PQerrorMessage(connection_.get()) << std::endl;
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
