@echo off
nasm -f win64 src/lib/rand_seed.asm -o build/rand_seed.obj
g++ -c src/lib/asm_helper.cpp -o build/asm_helper.obj
g++ build/rand_seed.obj build/asm_helper.obj -o build/rand_seed.exe