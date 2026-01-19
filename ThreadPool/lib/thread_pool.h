#pragma once

#include <queue>
#include <thread>
#include <vector>
#include <array>
#include <atomic>
#include <iostream>
#include <condition_variable>
#include <functional>
#include <mutex>
#include <assert.h>
#include <cstdint>
#include <future>

class ThreadPool {
private:
    std::mutex jobQueueMtx;

    std::atomic<uint32_t> threadsToEnd;
    std::condition_variable threadSleeper;
    
    std::vector<std::thread> threads;
    std::queue<std::function<void()>> jobs;    

    void threadPoolWorker();
public:
    // Initializes an empty thread pool
    ThreadPool();
    /*
    Initializes `numThreads` threads in the thread pool upon construction.
    
    Note: Significantly more threads than `hardware_concurrency` in the
    thread pool may decrease performance. However, in some cases, initializing
    a few more threads than `hardware_concurrency` can increase performance.
    */
    ThreadPool(size_t numThreads);
    ~ThreadPool();

    void queue_job(std::function<void()>&& function);
    template<typename F>
    [[nodiscard]] auto queue_async_job(std::function<void()>) -> std::future<F>;
    // Joins `num` threads in the thread pool
    void join_threads(size_t num);
    void join_threads();
    /*
    Adds `num` threads to the thread pool
    
    Note: Significantly more threads than `hardware_concurrency` in the
    thread pool may decrease performance. However, in some cases, initializing
    a few more threads than `hardware_concurrency` can increase performance.
    */
    void emplace_back(size_t num);
    // Adds 1 thread to the thread pool
    void emplace_back();

    inline size_t num_jobs() const {
        return jobs.size();
    }
    inline size_t num_threads() const {
        return threads.size();
    }
};
