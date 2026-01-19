#include <iostream>
#include <vector>
#include <random>
#include <ctime>
#include "lib/thread_pool.h"

#define print(...) std::cout << #__VA_ARGS__ << "\n"

// Check if a number is prime
inline bool isPrime(size_t num) {
    if (num < 2) return false;
    for (int i = 2; i * i <= num; ++i) {
        if (num % i == 0) return false;
    }
    return true;
}

// Find the nth prime number
int nthPrime(size_t n) {
    int count = 0;
    int candidate = 1;
    while (count < n) {
        candidate++;
        if (isPrime(candidate)) {
            count++;
        }
    }
    return candidate;
}

void findRandomPrime(size_t n) {
    if (n % 2000 == 0) {
        std::cout << "Finding the " << n << "th prime...\n";
    }
    int prime = nthPrime(n);
    if (n % 2000 == 0) {
        std::cout << n << "th prime is: " << prime << "\n";
    }
}

int main() {
    ThreadPool threadPool(std::thread::hardware_concurrency());
    std::cout << threadPool.num_threads() << "\n";
    for (int i = 0; i < 10'000; i++) {
        threadPool.queue_job(
            [=]{ if (i % 20 == 0) { print(a); } }
        );
        if (i == 5'000) {
            threadPool.join_threads(1);
        }
    }
    std::cout << threadPool.num_threads() << "\n";
    while (threadPool.num_jobs()) {}
    threadPool.join_threads();
    std::cout << "Joined Threads!\n";
    return 0;
}