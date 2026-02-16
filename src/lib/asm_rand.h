#pragma once
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

void throw_error(const char* msg); // for asm

// values used in asm
extern thread_local uint64_t state0;
extern thread_local uint64_t state1;
// functions defined in asm
uint64_t gen_seed(uint64_t min = 0, uint64_t = 0xFFFFFFFFFFFFFFFF);
uint64_t u_randint(uint64_t min, uint64_t max);
uint64_t randint(uint64_t min, uint64_t max);
uint64_t randint_biasless(uint64_t min, uint64_t max);
uint64_t gen_rand64();
void seed_states();


#ifdef __cplusplus
}
#endif