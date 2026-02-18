%define arg1 rcx
%define arg2 rdx
%define arg3 r8
%define arg4 r9
%define arg5 r10
%define arg6 r11
%define state0 [rcx]
%define state1 [rcx + 8]

%macro store_args 1-6
    %if %0 >= 1
        MOV arg1, %1
    %endif
    %if %0 >= 2
        MOV arg2, %2
    %endif
    %if %0 >= 3
        MOV arg3,  %3
    %endif
    %if %0 >= 4
        MOV arg4,  %4
    %endif
    %if %0 >= 5
        MOV arg5,  %5
    %endif
    %if %0 >= 6
        MOV arg6,  %6
    %endif
%endmacro

section .data
    invalid_inputs_msg: DB "Invalid argument(s). Arg min cannot be greater than arg max for RNG range specification.",0


section .text

extern _throw_logic_error



global gen_seed
gen_seed:
    CMP arg1,arg2
    JA .call_bad_arg_order
    JE .ret_min
    
    ;| Make Seed
    .seed__try_seed:
        RDSEED rax ; MULX uses rdx instead of rax
        JNC .seed__try_seed ; carry flag is clear, so it did not succeed
    MOV rdx,arg2 ; rbx = max
    SUB rdx,arg1 ; rbx = max - min
    MULX rax,rdx,rax ; low 64 bits go into rdx, high 64 bits go into rax (since multiplying two 64 bit unsigned ints together could result in 128 bits needed of total storage)
    ; this results in basically no bias (1 / (2^64) of bias, or ~0.00000000000000000005...)
    ADD rax,arg1 ; add min to shift into min max range
    ret

    .call_bad_arg_order:
        CALL err__bad_arg_order
        ret
    .ret_min:
        MOV rax,[arg1]
        ret

global gen_seed64
gen_seed64:
    seed64__try_seed:
        RDSEED rax
        JNC seed64__try_seed ; carry flag is clear, so it did not succeed
    ret


global gen_seed_biasless
gen_seed_biasless:
    CMP arg1,arg2
    JA .call_bad_arg_order
    JE .ret_min

    ;| Seed Biasless
    ; TODO
    ; FIXME: Finish
    %define x rax
    ; range = max - min + 1;
    SUB arg2,arg1
    ADD rdx,1 ; rdx now holds range
    ; save min for later (add to rax at end)
    MOV r9,arg1
    ; threshold = (-range) % range
    MOV rax,rdx ; rax now stores range
    MOV rcx,rdx ; rcx now stores range as well
    NEG rax ; (-range)
    XOR rdx,rdx ; clear higher 64 bits after rax
    DIV rcx ; now rdx stores the remainder of (-range) / range
    MOV r10,rdx ; now r10 holds threshold
    ; at this point, rcx stores range,
    ;                r10 stores threshold, and
    ;                rax and rdx are expendable
    ; gen seed
    .regen_seed:
        .try_seed:
            RDSEED rdx
            JNC .try_seed ; retry if it failed
        MULX rax, r8, rcx ; rax is hi, r8 is low
        CMP r8,r10
        JB .regen_seed ; if not low >= threshold, then retry, otherwise continue to the `ret` below
    ADD rax,r9
    ret

    ; FORMULA:
    ; uint64_t bounded_rand(uint64_t range) {
    ;     uint64_t threshold = (-range) % range; // precompute

    ;     while (1) {
    ;         uint64_t x = rng();           // 64-bit random
    ;         128bit prod = (128bit)x * range;
    ;         uint64_t hi = prod >> 64;
    ;         uint64_t lo = (uint64_t)prod; // low 64 bits
    ;         if (lo >= threshold)
    ;             return hi;                // result in [0, range]
    ;         // else repeat
    ;     }
    ; }
    ; Extras
    .call_bad_arg_order:
        CALL err__bad_arg_order
        ret
    .ret_min:
        MOV rax,[arg1]
        ret


global gen_randint
gen_randint: ; arg1 is RNGstate, arg2 is min, arg3 is max
    CMP arg2,arg3
    JA .call_bad_arg_order

    MOV r15,arg2 ; store min in r15 so it doesn't get overwritten
    CALL gen_rand64
    SUB arg3,arg2
    ADD arg3,1  ; for unsigned purposes
    MOV rdx,arg3 ; for MULX
    MULX rax,arg3,rax
    ADD rax,r15 ; add min
    ret

    .call_bad_arg_order:
        CALL err__bad_arg_order
        ret
    JE .ret_min
    .ret_min:
        MOV rax,arg2
        ret


global asm_randint_biasless
asm_randint_biasless:

    ; TODO: Create biasless randint generation
    ; FORMULA:
    ; uint64_t bounded_rand(uint64_t range) {
    ;     uint64_t threshold = (uint64_t)(-range) % range; // precompute

    ;     while (1) {
    ;         uint64_t x = rng();           // 64-bit random
    ;         unsigned __int128 prod = (unsigned __int128)x * range;
    ;         uint64_t hi = prod >> 64;
    ;         uint64_t lo = (uint64_t)prod; // low 64 bits
    ;         if (lo >= threshold)
    ;             return hi;                // result in [0, range)
    ;         // else repeat
    ;     }
    ; }


; VERIFIED
global seed_state
seed_state:
    CALL gen_seed64
    MOV qword state0,rax ; populate state0
   
   
    ;| SPLITMIX64
    ADD rax,0x9E3779B97F4A7C15 ; seed += 0x9E3779B97F4A7C15

    ; z = (z XOR (z >> 30)) * 0xBF58476D1CE4E5B9
    MOV r11,rax ; r11 = z
    SHR r11,30 ; (z >> 30)
    XOR rax,r11 ; z XOR (z >> 30)
    IMUL rax,0xBF58476D1CE4E5B9

    ; z = (z XOR (z >> 27)) * 0x94D049BB133111EB
    MOV r11,rax
    SHR r11,27 ; (z >> 27)
    XOR rax,r11 ; z XOR (z >> 27)
    IMUL rax,0x94D049BB133111EB
    
    ; return z XOR (z >> 31)
    MOV r11,rax
    SHR r11,31  ; (z >> 31)
    XOR rax,r11 ; z XOR (z >> 31)
    ; FORMULA:
    ;     seed += 0x9E3779B97F4A7C15
    ;     z = seed
    ;     z = (z XOR (z >> 30)) * 0xBF58476D1CE4E5B9
    ;     z = (z XOR (z >> 27)) * 0x94D049BB133111EB
    ;     return z XOR (z >> 31)
    ;| END SPLITMIX64


    MOV qword state1,rax ; populate state1. 8 Bytes ahead, since arg1 is a struct containing two uint64's
    ret


; TODO: Replace xiroshiro+ algorithm (biased) with xiroshrio++ algorithm (unbiased)
; VERIFIED (99%)
global gen_rand64
    gen_rand64:
        ; result = rotl(s0 + s1, 17) + s0;
        MOV rax,state0
        ADD rax,state1
        ROL rax,17
        ADD rax,state0 ; now rax holds `result`
        
        ; s1 ^= s0;
        XOR state1,state0
        ; s0 = rotl(s0, 49) ^ s1 ^ (s1 << 21);
        ROL state0,49
        XOR state0,state1
        MOV r8,state1
        SHL r8,21
        XOR state0,r8

        ; s1 = rotl(s1, 28);
        ROL state1,28

        ret

        ;# FORMULA:
        ; uint64_t xoroshiro128plusplus() {
        ;     uint64_t result = rotl(s0 + s1, 17) + s0;
        ;     s1 ^= s0;
        ;     s0 = rotl(s0, 49) ^ s1 ^ (s1 << 21);
        ;     s1 = rotl(s1, 28);
            
        ;     return result;
        ; }


err__bad_arg_order:
    LEA rcx,[rel invalid_inputs_msg]
    CALL _throw_logic_error
    ret
