#include "message_scheduler.h"
#include "../database/database.h"
#include <iostream>
#include <sstream>
#include <iomanip>
#include <ctime>

namespace messaging_service {

MessageScheduler::MessageScheduler(WorkerPool* worker_pool) 
    : worker_pool_(worker_pool) {
}

MessageScheduler::~MessageScheduler() {
    stop();
}

void MessageScheduler::start() {
    if (running_.load()) {
        return; // Already running
    }
    
    running_.store(true);
    scheduler_thread_ = std::thread(&MessageScheduler::schedulerLoop, this);
    std::cout << "[MESSAGE SCHEDULER] Started scheduler thread" << std::endl;
}

void MessageScheduler::stop() {
    if (!running_.load()) {
        return; // Already stopped
    }
    
    running_.store(false);
    cv_.notify_all(); // Wake up the scheduler thread
    
    if (scheduler_thread_.joinable()) {
        scheduler_thread_.join();
    }
    
    std::cout << "[MESSAGE SCHEDULER] Stopped scheduler thread" << std::endl;
}

void MessageScheduler::scheduleMessage(int message_id, int conversation_id,
                                     const std::string& from, const std::string& to,
                                     const std::string& type, const std::string& body,
                                     const std::string& attachments, const std::string& provider_message_id,
                                     const std::string& timestamp, const std::string& send_time,
                                     std::shared_ptr<MessagingProvider> provider) {
    
    auto scheduled_time = parseSendTime(send_time);
    auto current_time = std::chrono::system_clock::now();
    
    if (scheduled_time <= current_time) {
        std::cout << "[MESSAGE SCHEDULER] Scheduled time is in the past, sending immediately" << std::endl;
        // Send immediately
        ScheduledMessage message;
        message.send_time = current_time;
        message.message_id = message_id;
        message.conversation_id = conversation_id;
        message.from = from;
        message.to = to;
        message.type = type;
        message.body = body;
        message.attachments = attachments;
        message.provider_message_id = provider_message_id;
        message.timestamp = timestamp;
        message.provider = provider;
        
        sendScheduledMessage(message);
        return;
    }
    
    // Create scheduled message
    ScheduledMessage message;
    message.send_time = scheduled_time;
    message.message_id = message_id;
    message.conversation_id = conversation_id;
    message.from = from;
    message.to = to;
    message.type = type;
    message.body = body;
    message.attachments = attachments;
    message.provider_message_id = provider_message_id;
    message.timestamp = timestamp;
    message.provider = provider;
    
    // Add to priority queue
    {
        std::lock_guard<std::mutex> lock(queue_mutex_);
        scheduled_messages_.push(message);
    }
    
    // Notify scheduler thread
    cv_.notify_one();
    
    auto delay = std::chrono::duration_cast<std::chrono::seconds>(scheduled_time - current_time);
    std::cout << "[MESSAGE SCHEDULER] Scheduled message " << message_id << " for delivery in " 
              << delay.count() << " seconds" << std::endl;
}

size_t MessageScheduler::getScheduledMessageCount() const {
    std::lock_guard<std::mutex> lock(queue_mutex_);
    return scheduled_messages_.size();
}

void MessageScheduler::schedulerLoop() {
    std::cout << "[MESSAGE SCHEDULER] Scheduler loop started" << std::endl;
    
    while (running_.load()) {
        std::unique_lock<std::mutex> lock(queue_mutex_);
        
        if (scheduled_messages_.empty()) {
            // No messages scheduled, wait indefinitely until notified
            cv_.wait(lock, [this] { return !running_.load() || !scheduled_messages_.empty(); });
            continue;
        }
        
        // Get the next message to be sent
        auto next_message = scheduled_messages_.top();
        auto now = std::chrono::system_clock::now();
        
        if (next_message.send_time <= now) {
            // Time to send this message
            scheduled_messages_.pop();
            lock.unlock(); // Release lock before sending
            
            std::cout << "[MESSAGE SCHEDULER] Sending scheduled message " << next_message.message_id << std::endl;
            sendScheduledMessage(next_message);
        } else {
            // Wait until the next message is due
            cv_.wait_until(lock, next_message.send_time, [this, &next_message] {
                return !running_.load() || 
                       scheduled_messages_.empty() || 
                       scheduled_messages_.top().send_time != next_message.send_time;
            });
        }
    }
    
    std::cout << "[MESSAGE SCHEDULER] Scheduler loop ended" << std::endl;
}

void MessageScheduler::sendScheduledMessage(const ScheduledMessage& message) {
    // Submit to worker pool for actual sending
    worker_pool_->submit([this, message]() {
        std::cout << "[MESSAGE SCHEDULER] Executing scheduled message send for message " << message.message_id << std::endl;
        
        // Create message request
        MessageRequest messageRequest(message.from, message.to, message.type, message.body, 
                                    message.provider->getProviderName(), message.timestamp, "outbound");
        
        // Parse attachments if provided
        if (message.attachments != "null" && !message.attachments.empty()) {
            if (message.attachments.find('[') != std::string::npos) {
                messageRequest.attachments = {message.attachments};
            } else {
                messageRequest.attachments = {message.attachments};
            }
        }
        
        // Send the message
        auto response = message.provider->sendMessage(messageRequest);
        
        // Update the sent_time in the database
        Database db;
        if (db.connect()) {
            std::string currentTime = getCurrentTimestamp();
            
            // Update the specific message's sent_time field
            if (response.success) {
                if (db.updateMessageSentTime(message.message_id, currentTime)) {
                    std::cout << "[MESSAGE SCHEDULER] Updated sent_time for message " << message.message_id 
                              << " to " << currentTime << std::endl;
                } else {
                    std::cerr << "[MESSAGE SCHEDULER] Failed to update sent_time for message " << message.message_id << std::endl;
                }
            } else {
                std::cerr << "[MESSAGE SCHEDULER] Scheduled message send failed for message " << message.message_id 
                          << ": " << response.message << std::endl;
            }
        } else {
            std::cerr << "[MESSAGE SCHEDULER] Failed to connect to database to update sent_time for message " 
                      << message.message_id << std::endl;
        }
    });
}

std::chrono::system_clock::time_point MessageScheduler::parseSendTime(const std::string& send_time) {
    // Parse ISO 8601 timestamp (e.g., "2024-01-15T14:30:00.000Z")
    std::tm tm = {};
    std::istringstream ss(send_time);
    ss >> std::get_time(&tm, "%Y-%m-%dT%H:%M:%S");
    
    if (ss.fail()) {
        std::cerr << "[MESSAGE SCHEDULER] Failed to parse scheduled time: " << send_time << std::endl;
        return std::chrono::system_clock::now(); // Return current time as fallback
    }
    
    // Convert to time_t and then to system_clock::time_point
    auto time_t_val = std::mktime(&tm);
    return std::chrono::system_clock::from_time_t(time_t_val);
}

std::string MessageScheduler::getCurrentTimestamp() {
    auto now = std::chrono::system_clock::now();
    auto time_t = std::chrono::system_clock::to_time_t(now);
    auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(now.time_since_epoch()) % 1000;
    
    std::stringstream ss;
    ss << std::put_time(std::gmtime(&time_t), "%Y-%m-%dT%H:%M:%S");
    ss << '.' << std::setfill('0') << std::setw(3) << ms.count() << 'Z';
    return ss.str();
}

} // namespace messaging_service
