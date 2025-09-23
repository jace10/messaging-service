#pragma once

#include "../messaging_provider.h"
#include <string>
#include <vector>

namespace messaging_service {

/**
 * @brief Default implementation of MessagingProvider that simulates successful sends
 * This provider always returns success without making external API calls
 */
class DefaultMessagingProvider : public MessagingProvider {
private:
    std::string providerName_;
    std::vector<std::string> supportedTypes_;
    
public:
    /**
     * @brief Constructor for DefaultMessagingProvider
     * @param providerName The name identifier for this provider
     * @param supportedTypes Vector of message types this provider supports (e.g., "sms", "email")
     */
    DefaultMessagingProvider(const std::string& providerName, 
                           const std::vector<std::string>& supportedTypes);
    
    /**
     * @brief Send a message through this provider (simulated)
     * @param request The message request containing all necessary data
     * @return Response indicating simulated success with mock message ID
     */
    MessageResponse sendMessage(const MessageRequest& request) override;
    
    /**
     * @brief Get the provider name/identifier
     * @return Provider name as specified in constructor
     */
    std::string getProviderName() const override;
    
    /**
     * @brief Check if this provider supports the given message type
     * @param messageType The type of message to check (sms, mms, email)
     * @return true if message type is in supported types list, false otherwise
     */
    bool supportsMessageType(const std::string& messageType) const override;
    
private:
    /**
     * @brief Generate a mock message ID for simulated responses
     * @return Randomly generated message ID string
     */
    std::string generateMockMessageId();
};

} // namespace messaging_service
