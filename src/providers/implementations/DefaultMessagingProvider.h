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
    DefaultMessagingProvider(const std::string& providerName, 
                           const std::vector<std::string>& supportedTypes);
    
    MessageResponse sendMessage(const MessageRequest& request) override;
    std::string getProviderName() const override;
    bool supportsMessageType(const std::string& messageType) const override;
    
private:
    std::string generateMockMessageId();
};

} // namespace messaging_service
