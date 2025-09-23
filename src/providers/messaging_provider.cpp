#include "messaging_provider.h"
#include "implementations/DefaultMessagingProvider.h"
#include <iostream>
#include <map>

namespace messaging_service {

// Provider registry
static std::map<std::string, std::shared_ptr<MessagingProvider>> providerRegistry;
static std::map<std::string, std::string> typeToProviderMapping;

// Initialize default providers
static void initializeDefaultProviders() {
    static bool initialized = false;
    if (initialized) return;
    
    // Default SMS/MMS provider
    providerRegistry["default_sms"] = std::make_shared<DefaultMessagingProvider>(
        "default_sms", std::vector<std::string>{"sms", "mms"});
    
    // Default Email provider
    providerRegistry["default_email"] = std::make_shared<DefaultMessagingProvider>(
        "default_email", std::vector<std::string>{"email"});
    
    // Twilio simulation
    providerRegistry["twilio"] = std::make_shared<DefaultMessagingProvider>(
        "twilio", std::vector<std::string>{"sms", "mms"});
    
    // SendGrid simulation
    providerRegistry["sendgrid"] = std::make_shared<DefaultMessagingProvider>(
        "sendgrid", std::vector<std::string>{"email"});
    
    // Xillio simulation
    providerRegistry["xillio"] = std::make_shared<DefaultMessagingProvider>(
        "xillio", std::vector<std::string>{"email"});
    
    // Set up default type-to-provider mappings
    typeToProviderMapping["sms"] = "default_sms";
    typeToProviderMapping["mms"] = "default_sms";
    typeToProviderMapping["email"] = "default_email";
    
    initialized = true;
}

std::shared_ptr<MessagingProvider> MessagingProviderFactory::createProvider(const std::string& providerName) {
    initializeDefaultProviders();
    
    auto it = providerRegistry.find(providerName);
    if (it != providerRegistry.end()) {
        return it->second;
    }
    
    return nullptr;
}

std::shared_ptr<MessagingProvider> MessagingProviderFactory::getProviderForType(const std::string& messageType) {
    initializeDefaultProviders();
    
    auto it = typeToProviderMapping.find(messageType);
    if (it != typeToProviderMapping.end()) {
        return createProvider(it->second);
    }
    
    return nullptr;
}

bool MessagingProviderFactory::setProviderForType(const std::string& messageType, const std::string& providerName) {
    initializeDefaultProviders();
    
    // Check if the provider exists
    auto providerIt = providerRegistry.find(providerName);
    if (providerIt == providerRegistry.end()) {
        return false;
    }
    
    // Check if the provider supports this message type
    if (!providerIt->second->supportsMessageType(messageType)) {
        return false;
    }
    
    // Set the mapping
    typeToProviderMapping[messageType] = providerName;
    return true;
}

void MessagingProviderFactory::registerProvider(const std::string& providerName, 
                                               std::shared_ptr<MessagingProvider> provider) {
    providerRegistry[providerName] = provider;
}

std::vector<std::string> MessagingProviderFactory::getAvailableProviders() {
    initializeDefaultProviders();
    
    std::vector<std::string> providers;
    for (const auto& pair : providerRegistry) {
        providers.push_back(pair.first);
    }
    return providers;
}

std::map<std::string, std::string> MessagingProviderFactory::getProviderMappings() {
    initializeDefaultProviders();
    
    return typeToProviderMapping;
}

} // namespace messaging_service
