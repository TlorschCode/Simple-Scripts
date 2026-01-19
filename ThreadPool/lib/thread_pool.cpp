#include "thread_pool.h"


//| MARK: Constructors

// Default constructor for a ThreadPool
ThreadPool::ThreadPool() : threads(), jobs(), threadsToEnd(0) {}

ThreadPool::ThreadPool(size_t numThreads) : jobs(), threadsToEnd(0) {
    emplace_back(numThreads);
}

//| MARK: Destructor
ThreadPool::~ThreadPool() {
    join_threads();
}


//| MARK: Runtime functions
/*
Adds a function to the process queue.

Pass a lambda that calls the function to include paramaters. e.g.
`threadPool.queue_job(std::move([]{ foo(1, 2); }));`

Takes the function by rvalue to improve performance.
*/
void ThreadPool::queue_job(std::function<void()>&& function) {
    std::unique_lock<std::mutex> jobQueueLock(jobQueueMtx);
    jobs.push(std::move(function));
    jobQueueLock.unlock();
    threadSleeper.notify_one();
}

void ThreadPool::join_threads(size_t num) {
    for (size_t i = std::min(threads.size(), num); i > 0; i--) {
        threadsToEnd.store(num);
        threadSleeper.notify_all();
    }
}

void ThreadPool::join_threads() {
    threadsToEnd.store(num_threads());
    threadSleeper.notify_all(); // Wake up all threads
    while (!threads.empty()) {
        if (threads.back().joinable()) {
            threads.back().join();
        }
        threads.pop_back();
    }
}

void ThreadPool::emplace_back(size_t num) {
    for (size_t i = 0; i < num; i++) {
        threads.emplace_back(&ThreadPool::threadPoolWorker, this);
    }
}

void ThreadPool::emplace_back() {
    threads.emplace_back(&ThreadPool::threadPoolWorker, this);
}




//| Worker Function

void ThreadPool::threadPoolWorker() {
    while (true) {
        std::function<void()> job;

        {
            std::unique_lock<std::mutex> queueLock(jobQueueMtx);
            threadSleeper.wait(queueLock, [&]{
                return threadsToEnd.load() > 0 || !jobs.empty(); // wait until the pool is being destructed or there is a job.
            });                                                  // Only lets one thread through at a time.

            if (threadsToEnd.load() > 0) {
                this->threadsToEnd.store(threadsToEnd.load() - 1);
                return; // shutdown
            }

            // Safely get the next job
            if (!jobs.empty()) {
                job = std::move(jobs.front());
                jobs.pop();
            }
        }

        // Execute the job if it is validi
        if (job) job();
    }
}

