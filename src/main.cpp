#include <iostream>
#include <memory>
#include "server.h"

int main() {
    std::cout << "Starting Messaging Service..." << std::endl;
    
    try {
        auto server = std::make_unique<MessagingServer>();
        server->start();
    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return 1;
    }
    
    return 0;
}
