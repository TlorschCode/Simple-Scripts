#pragma once
#include <stdint.h>
#include <cstddef>
#include <stdexcept>


struct RNGstate {
    uint64_t state0;
    uint64_t state1;
};

#ifdef __cplusplus
extern "C" {
#endif

// functions defined in asm
uint64_t asm_gen_seed_biasless(uint64_t min = 0, uint64_t = 0xFFFFFFFFFFFFFFFF);
uint64_t asm_gen_seed(uint64_t min = 0, uint64_t = 0xFFFFFFFFFFFFFFFF);
uint64_t asm_randint(RNGstate& state, uint64_t min, uint64_t max);
uint64_t asm_randint_biasless(RNGstate& state, uint64_t min, uint64_t max);
uint64_t asm_gen_rand64(RNGstate& state);
void asm_seed_state(RNGstate& state);


#ifdef __cplusplus
}
#endif