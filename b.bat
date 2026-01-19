@echo off

g++ -std=c++17 -O3 -march=native -flto -pthread -I src/lib src/main.cpp src/lib/thread_pool.cpp -o threadpool_app

echo Built!

cmd /k threadpool_app.exe