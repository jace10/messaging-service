#include <iostream>
#include <memory>
#include <string>
#include "server/server.h"

int main(int argc, char* argv[]) {
    int port = 8080; // Default port
    
    // Parse command line arguments
    if (argc > 1) {
        try {
            port = std::stoi(argv[1]);
            if (port < 1 || port > 65535) {
                std::cerr << "Error: Port must be between 1 and 65535" << std::endl;
                return 1;
            }
        } catch (const std::exception& e) {
            std::cerr << "Error: Invalid port number '" << argv[1] << "'" << std::endl;
            std::cerr << "Usage: " << argv[0] << " [port]" << std::endl;
            return 1;
        }
    }
    
    std::cout << "Starting Messaging Service on port " << port << "..." << std::endl;
    
    try {
        auto server = std::make_unique<MessagingServer>(port);
        server->start();
    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return 1;
    }
    
    return 0;
}
