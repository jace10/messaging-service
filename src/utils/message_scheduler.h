#pragma once

#include <queue>
#include <mutex>
#include <condition_variable>
#include <thread>
#include <atomic>
#include <chrono>
#include <memory>
#include <string>

#include "worker_pool.h"
#include "../providers/messaging_provider.h"

namespace messaging_service {

struct ScheduledMessage {
    std::chrono::system_clock::time_point send_time;
    int message_id;
    int conversation_id;
    std::string from;
    std::string to;
    std::string type;
    std::string body;
    std::string attachments;
    std::string provider_message_id;
    std::string timestamp;
    std::shared_ptr<MessagingProvider> provider;
    
    // For min-heap (earliest time first)
    bool operator>(const ScheduledMessage& other) const {
        return send_time > other.send_time;
    }
};

class MessageScheduler {
public:
    MessageScheduler(WorkerPool* worker_pool);
    ~MessageScheduler();
    
    // Start the scheduler thread
    void start();
    
    // Stop the scheduler thread
    void stop();
    
    // Schedule a message for future delivery
    void scheduleMessage(int message_id, int conversation_id,
                        const std::string& from, const std::string& to,
                        const std::string& type, const std::string& body,
                        const std::string& attachments, const std::string& provider_message_id,
                        const std::string& timestamp, const std::string& send_time,
                        std::shared_ptr<MessagingProvider> provider);
    
    // Get the number of scheduled messages
    size_t getScheduledMessageCount() const;
    
private:
    // The main scheduler loop
    void schedulerLoop();
    
    // Send a scheduled message
    void sendScheduledMessage(const ScheduledMessage& message);
    
    // Parse send_time string to time_point
    std::chrono::system_clock::time_point parseSendTime(const std::string& send_time);
    
    // Get current timestamp in ISO format
    std::string getCurrentTimestamp();
    
    // Priority queue for scheduled messages (min-heap)
    std::priority_queue<ScheduledMessage, std::vector<ScheduledMessage>, std::greater<ScheduledMessage>> scheduled_messages_;
    
    // Thread synchronization
    mutable std::mutex queue_mutex_;
    std::condition_variable cv_;
    std::thread scheduler_thread_;
    std::atomic<bool> running_{false};
    
    // Worker pool for sending messages
    WorkerPool* worker_pool_;
};

} // namespace messaging_service
