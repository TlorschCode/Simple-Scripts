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

//? functions defined in asm



//|MARK: Gen Normal

// Generates a biasless, truly random number using the `RDSEED` assembly instruction.
//
// It is recommended to use this to seed an RNG rather than act as a standalone one, since it is ~500x slower than `gen_randint`/`gen_randint_fast` (which are pseudoRNG's).
uint64_t gen_seed(uint64_t min, uint64_t max);

// Generates a high-quality, biasless, pseudorandom number from `min` to `max` (inclusive).
// Uses `xoroshiro++`, a general purpose pseudoRNG algorithm.
uint64_t gen_urandint(RNGstate& state, uint64_t min, uint64_t max);

// Generates a high-quality, biasless, pseudorandom number from `min` to `max` (inclusive).
// Uses `xoroshiro**`, which is higher quality than `gen_randint`'s `xoroshiro++`.
// Is ~15% slower than `gen_randint`.
uint64_t gen_urandintHQ(RNGstate& state, uint64_t min, uint64_t max);



//|MARK: Gen 64

// Generates a biasless, truly random number from 0 to 2^64 (inclusive) using assembly's `RDSEED` instruction.
uint64_t gen_seed64();

// Generates a high-quality, biasless random number from 0 to 2^64 (inclusive).
// Uses a `xoroshiro++`, a general-purpose pseudoRNG.
uint64_t gen_rand64(RNGstate& state);

// Generates a high-quality, biasless random number from 0 to 2^64 (inclusive).
// Uses a higher-quality pseudoRNG (`xoroshiro**`) than `gen_rand64`, which uses `xoroshiro++`.
// Is ~15% slower than `gen_rand64`.
uint64_t gen_rand64HQ(RNGstate& state);



//|MARK: Seed State

// Seeds an RNGstate struct using a true random number generator (`RDSEED`) paired with `splitmix64`.
void seed_state(RNGstate& state);


#ifdef __cplusplus
}
#endif