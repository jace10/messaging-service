#include "worker_pool.h"
#include <iostream>
#include <algorithm>

namespace messaging_service {

WorkerPool::WorkerPool(size_t numWorkers) 
    : numWorkers_(numWorkers), stop_(false), running_(true), pendingTasks_(0) {
    
    // Create worker threads
    workers_.reserve(numWorkers_);
    for (size_t i = 0; i < numWorkers_; ++i) {
        workers_.emplace_back(&WorkerPool::workerLoop, this);
    }
    
    std::cout << "[WORKER POOL] Initialized with " << numWorkers_ << " workers" << std::endl;
}

WorkerPool::~WorkerPool() {
    stop();
}

void WorkerPool::workerLoop() {
    while (true) {
        std::function<void()> task;
        
        {
            // Lock the queue
            std::unique_lock<std::mutex> lock(queueMutex_);
            
            // Wait for a task or stop signal
            condition_.wait(lock, [this] { return stop_ || !tasks_.empty(); });
            
            // Check if we should stop
            if (stop_ && tasks_.empty()) {
                break;
            }
            
            // Get the next task
            if (!tasks_.empty()) {
                task = std::move(tasks_.front());
                tasks_.pop();
                pendingTasks_--;
            }
        }
        
        // Execute the task
        if (task) {
            try {
                task();
            } catch (const std::exception& e) {
                std::cerr << "[WORKER POOL] Task execution failed: " << e.what() << std::endl;
            }
        }
    }
}

std::thread& WorkerPool::getNextAvailableWorker() {
    // Simple round-robin selection
    // In a more sophisticated implementation, we could track worker availability
    static size_t currentWorker = 0;
    currentWorker = (currentWorker + 1) % numWorkers_;
    return workers_[currentWorker];
}

size_t WorkerPool::getWorkerCount() const {
    return numWorkers_;
}

size_t WorkerPool::getPendingTaskCount() const {
    return pendingTasks_.load();
}

bool WorkerPool::isRunning() const {
    return running_.load();
}

void WorkerPool::stop() {
    if (stop_) {
        return; // Already stopped
    }
    
    std::cout << "[WORKER POOL] Stopping worker pool..." << std::endl;
    
    {
        // Signal all workers to stop
        std::unique_lock<std::mutex> lock(queueMutex_);
        stop_ = true;
    }
    
    // Notify all workers
    condition_.notify_all();
    
    // Wait for all workers to finish
    for (auto& worker : workers_) {
        if (worker.joinable()) {
            worker.join();
        }
    }
    
    running_ = false;
    std::cout << "[WORKER POOL] Worker pool stopped" << std::endl;
}

} // namespace messaging_service
