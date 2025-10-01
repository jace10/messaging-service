#pragma once

#include <thread>
#include <vector>
#include <queue>
#include <mutex>
#include <condition_variable>
#include <functional>
#include <future>
#include <atomic>
#include <memory>

namespace messaging_service {

/**
 * @brief Thread-safe worker pool for handling provider sendMessage operations
 */
class WorkerPool {
public:
    /**
     * @brief Constructor with configurable number of workers
     * @param numWorkers Number of worker threads (default: 10)
     */
    explicit WorkerPool(size_t numWorkers = 10);
    
    /**
     * @brief Destructor - stops all workers and waits for completion
     */
    ~WorkerPool();
    
    /**
     * @brief Submit a task to the worker pool
     * @param task Function to execute
     * @return Future containing the result of the task
     */
    template<typename F, typename... Args>
    auto submit(F&& f, Args&&... args) -> std::future<decltype(f(args...))>;
    
    /**
     * @brief Get the number of active workers
     * @return Number of worker threads
     */
    size_t getWorkerCount() const;
    
    /**
     * @brief Get the number of pending tasks
     * @return Number of tasks waiting to be processed
     */
    size_t getPendingTaskCount() const;
    
    /**
     * @brief Check if the worker pool is running
     * @return true if running, false if stopped
     */
    bool isRunning() const;
    
    /**
     * @brief Stop the worker pool and wait for all tasks to complete
     */
    void stop();

private:
    // Worker thread function
    void workerLoop();
    
    // Find next available worker
    std::thread& getNextAvailableWorker();
    
    // Number of worker threads
    size_t numWorkers_;
    
    // Worker threads
    std::vector<std::thread> workers_;
    
    // Task queue
    std::queue<std::function<void()>> tasks_;
    
    // Synchronization primitives
    mutable std::mutex queueMutex_;
    std::condition_variable condition_;
    
    // Control flags
    std::atomic<bool> stop_;
    std::atomic<bool> running_;
    
    // Statistics
    mutable std::mutex statsMutex_;
    std::atomic<size_t> pendingTasks_;
};

// Template implementation
template<typename F, typename... Args>
auto WorkerPool::submit(F&& f, Args&&... args) -> std::future<decltype(f(args...))> {
    using ReturnType = decltype(f(args...));
    
    // Create a packaged task
    auto task = std::make_shared<std::packaged_task<ReturnType()>>(
        std::bind(std::forward<F>(f), std::forward<Args>(args)...)
    );
    
    // Get future from the task
    std::future<ReturnType> result = task->get_future();
    
    {
        // Lock the queue
        std::unique_lock<std::mutex> lock(queueMutex_);
        
        // Check if we can accept new tasks
        if (stop_) {
            throw std::runtime_error("WorkerPool is stopped");
        }
        
        // Add task to queue
        tasks_.emplace([task]() { (*task)(); });
        pendingTasks_++;
    }
    
    // Notify one worker
    condition_.notify_one();
    
    return result;
}

} // namespace messaging_service
