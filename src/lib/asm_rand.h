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

// Generates a biasless *truly* random number using the RDSEED instruction.
// Ensures biaslessness using Lemire's rejection sampling method
// The alternative (`gen_seed()`) introduces a slight bias to numbers (~1 / 2^64, or 0.00000000000000000005)
uint64_t gen_seed_biasless(uint64_t min, uint64_t max);
uint64_t gen_seed();
uint64_t gen_seed64(uint64_t min, uint64_t max);
uint64_t gen_randint(RNGstate& state, uint64_t min, uint64_t max);
uint64_t gen_randint_biasless(RNGstate& state, uint64_t min, uint64_t max);
uint64_t gen_rand64(RNGstate& state);
void seed_state(RNGstate& state);


#ifdef __cplusplus
}
#endif