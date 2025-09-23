#include "DefaultMessagingProvider.h"
#include <iostream>
#include <random>
#include <sstream>
#include <algorithm>

namespace messaging_service {

DefaultMessagingProvider::DefaultMessagingProvider(const std::string& providerName, 
                                                   const std::vector<std::string>& supportedTypes)
    : providerName_(providerName), supportedTypes_(supportedTypes) {}

MessageResponse DefaultMessagingProvider::sendMessage(const MessageRequest& request) {
    // Generate a mock provider message ID
    std::string mockMessageId = generateMockMessageId();
    
    // Log the simulated send
    std::cout << "[DEFAULT PROVIDER] Simulating send via " << providerName_ 
              << " - From: " << request.from 
              << ", To: " << request.to 
              << ", Type: " << request.type
              << ", Message ID: " << mockMessageId << std::endl;
    
    // Always return success
    return MessageResponse(true, 
                          "Message sent successfully via " + providerName_,
                          mockMessageId,
                          200);
}

std::string DefaultMessagingProvider::getProviderName() const {
    return providerName_;
}

bool DefaultMessagingProvider::supportsMessageType(const std::string& messageType) const {
    return std::find(supportedTypes_.begin(), supportedTypes_.end(), messageType) 
           != supportedTypes_.end();
}

std::string DefaultMessagingProvider::generateMockMessageId() {
    static std::random_device rd;
    static std::mt19937 gen(rd());
    static std::uniform_int_distribution<> dis(100000, 999999);
    
    std::ostringstream oss;
    oss << providerName_ << "_" << dis(gen);
    return oss.str();
}

} // namespace messaging_service
