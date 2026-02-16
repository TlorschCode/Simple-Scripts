@echo off
nasm -f win64 src/lib/asm_rand.asm -o asm_rand.obj
g++ -std=c++17 -Isrc/lib src/lib/asm_helper.cpp src/main.cpp asm_rand.obj -o main.exe

cmd /k main.exe
