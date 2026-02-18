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

// Generates a completely biasless truly random number using the `RDSEED` assembly instruction.
// Ensures biaslessness using Lemire's rejection sampling method.
//
// This function's somewhat faster alternative `gen_seed()` introduces a slight bias to numbers (1 / 2^64, meaning some numbers are ~0.00000000000000000005% more likely to be generated).
//
// It is reccomended to only use this to seed an RNG, since it is ~500x slower than `gen_randint`/`gen_randint_biasless` (which are pseudoRNG's).
uint64_t gen_seed_biasless(uint64_t min, uint64_t max);

// Generates a truly random number using the `RDSEED` assembly instruction.
//
// This function is faster than `gen_seed_biasless`, but introduces a slight bias to the randomness.
// Some numbers are 1 / 2^64 times more likely to appear (~0.00000000000000000005% more likely to appear).
uint64_t gen_seed(uint64_t min, uint64_t max);

// Generates a completely biasless truly random number from 0 to 2^64 using assembly's `RDSEED` instruction.
uint64_t gen_seed64();

// Generates a high-quality pseudorandom number using 
uint64_t gen_randint(RNGstate& state, uint64_t min, uint64_t max);
uint64_t gen_randint_biasless(RNGstate& state, uint64_t min, uint64_t max);
uint64_t gen_rand64(RNGstate& state);
void seed_state(RNGstate& state);


#ifdef __cplusplus
}
#endif