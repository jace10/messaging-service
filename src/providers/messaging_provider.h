#pragma once

#include <string>
#include <vector>
#include <memory>
#include <map>

namespace messaging_service {

// Forward declarations
struct MessageRequest;
struct MessageResponse;

/**
 * @brief Interface for messaging providers (SMS, Email, etc.)
 */
class MessagingProvider {
public:
    virtual ~MessagingProvider() = default;
    
    /**
     * @brief Send a message through this provider
     * @param request The message request containing all necessary data
     * @return Response indicating success/failure and any provider-specific data
     */
    virtual MessageResponse sendMessage(const MessageRequest& request) = 0;
    
    /**
     * @brief Get the provider name/identifier
     * @return Provider name (e.g., "twilio", "sendgrid", "xillio")
     */
    virtual std::string getProviderName() const = 0;
    
    /**
     * @brief Check if this provider supports the given message type
     * @param messageType The type of message (sms, mms, email)
     * @return true if supported, false otherwise
     */
    virtual bool supportsMessageType(const std::string& messageType) const = 0;
};

/**
 * @brief Request structure for sending messages
 */
struct MessageRequest {
    std::string from;
    std::string to;
    std::string type;           // sms, mms, email
    std::string body;
    std::string subject;        // For email only
    std::vector<std::string> attachments;
    std::string messaging_provider_id;
    std::string timestamp;
    std::string direction;      // inbound, outbound
    
    MessageRequest() = default;
    
    MessageRequest(const std::string& from, const std::string& to, 
                   const std::string& type, const std::string& body,
                   const std::string& messaging_provider_id, const std::string& timestamp,
                   const std::string& direction = "outbound")
        : from(from), to(to), type(type), body(body), 
          messaging_provider_id(messaging_provider_id), timestamp(timestamp), direction(direction) {}
};

/**
 * @brief Response structure from messaging providers
 */
struct MessageResponse {
    bool success;
    std::string message;
    std::string provider_message_id;  // Provider's internal message ID
    int http_status_code;
    std::string error_code;           // Provider-specific error code
    
    MessageResponse() : success(false), http_status_code(500) {}
    
    MessageResponse(bool success, const std::string& message, 
                   const std::string& provider_message_id = "",
                   int http_status_code = 200)
        : success(success), message(message), provider_message_id(provider_message_id),
          http_status_code(http_status_code) {}
};

/**
 * @brief Factory for creating messaging providers
 */
class MessagingProviderFactory {
public:
    /**
     * @brief Create a provider instance based on provider name
     * @param providerName The name of the provider (twilio, sendgrid, xillio, default)
     * @return Shared pointer to the provider, or nullptr if not found
     */
    static std::shared_ptr<MessagingProvider> createProvider(const std::string& providerName);
    
    /**
     * @brief Get the provider for a given message type
     * @param messageType The type of message (sms, mms, email)
     * @return Shared pointer to the provider for this message type
     */
    static std::shared_ptr<MessagingProvider> getProviderForType(const std::string& messageType);
    
    /**
     * @brief Set the provider for a specific message type
     * @param messageType The type of message (sms, mms, email)
     * @param providerName The name of the provider to use for this type
     * @return true if successful, false if provider not found
     */
    static bool setProviderForType(const std::string& messageType, const std::string& providerName);
    
    /**
     * @brief Register a custom provider
     * @param providerName The name to register the provider under
     * @param provider Shared pointer to the provider instance
     */
    static void registerProvider(const std::string& providerName, 
                               std::shared_ptr<MessagingProvider> provider);
    
    /**
     * @brief Get list of available providers
     * @return Vector of provider names
     */
    static std::vector<std::string> getAvailableProviders();
    
    /**
     * @brief Get the current provider mapping for all message types
     * @return Map of message type to provider name
     */
    static std::map<std::string, std::string> getProviderMappings();
};

} // namespace messaging_service
