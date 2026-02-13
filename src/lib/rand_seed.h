// rand_seed.h
#pragma once
#include <cstdint>

extern "C" {
    void throw_error(const char*);   // called by asm when invalid args
    uint64_t gen_seed(uint64_t min, uint64_t max);
    uint64_t gen_randint(uint64_t min, uint64_t max);
}