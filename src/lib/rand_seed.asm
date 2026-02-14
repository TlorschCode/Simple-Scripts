; nasm -f elf64 rand_seed.asm -o rand_seed.o
; ld rand_seed.o -o rand_seed
; ./rand_seed

%include "src/lib/bit_size_enums.inc"

%define arg1 rcx
%define arg2 rdx
%define arg3 r8
%define arg4 r9
%define arg5 r10
%define arg6 r11

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

; macro for speed (no function skipping around on the stack)
%macro rot_left 0
    MOV rax, arg1    ; value to rotate
    MOV cl, arg2b    ; lower 8 bits of arg2 (rotation count)
    ROL rax, cl
    ret
%endmacro


section .data
    invalid_val_arg_msg: DB "Invalid Int",0
    invalid_inputs_msg: DB "Minimum cannot be greater than maximum",0


section .bss
    align 16 ; align the followign values to memory locations divisible by 16 for faster access
    state0: RESQ 1
    state1: RESQ 1


section .text

extern _throw_runtime_error
extern _throw_logic_error
global randint
global randint_biasless
global gen_seed
global gen_seed_biasless


pow:
    TEST arg2,0 ; performs and op on the values, but only modifies flags
    JZ pow_base_case
    MOV rbx,arg2
    pow_loop:
        TEST rbx,0
        JZ end_pow
        MUL arg1,arg1
        DEC rbx
        JMP pow_loop
    pow_base_case:
        MOV rax,1
        ret
    end_pow:
        ret
    

gen_seed:
    CMP arg1,arg2
    JA .call_bad_arg_order
    JE seed__rangeless_so_ret_min
    JMP seed__gen_num
    .call_bad_arg_order:
        call err__bad_arg_order
        JMP end_func__seed
    seed__rangeless_so_ret_min:
        MOV rax,[arg1]
        ret
    seed__gen_num:
        RDSEED rax ; MULX uses rdx instead of rax
        MOV rdx,arg2 ; rbx = max
        SUB rdx,arg1 ; rbx = max - min
        MULX rax,rdx,rax ; low 64 bits go into rdx, high 64 bits go into rax (since multiplying two 64 bit unsigned ints together could result in 128 bits needed of total storage)
        ; this results in basically no bias (1 / (2^64) of bias, or ~0.00000000000000000005...)
        ADD rax,arg1 ; add min to shift into min max range
        ret


gen_seed_biasless:
    ; TODO: Create biasless seed generation
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


randint:
    CALL gen_rand64
    MOV rdx,arg2
    SUB rdx,arg1
    MULX rax,rdx,rax
    ADD rax,arg1
    ret


randint_biasless:
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
seed_states:
    CALL gen_seed
    MOV [state0],rax ; populate state0
    MOV arg1,rax
    CALL splitmix64
    MOV [state1],rax ; populate state1
    ret


; VERIFIED
splitmix64:
    ; seed += 0x9E3779B97F4A7C15
    ADD arg1,0x9E3779B97F4A7C15
    MOV rax,arg1 ; z = seed. rax is persistently z


    ; z = (z XOR (z >> 30)) * 0xBF58476D1CE4E5B9
    MOV r11,rax ; r11 = z
    SHR r11,30 ; (z >> 30)
    XOR rax,r11 ; z XOR (z >> 30)
    IMUL qword rax,0xBF58476D1CE4E5B9


    ; z = (z XOR (z >> 27)) * 0x94D049BB133111EB
    MOV r11,rax
    SHR r11,27 ; (z >> 27)
    XOR rax,r11 ; z XOR (z >> 27)
    IMUL rax,0x94D049BB133111EB
    

    ; return z XOR (z >> 31)
    MOV r11,rax
    SHR r11,31  ; (z >> 31)
    XOR rax,r11 ; z XOR (z >> 31)
    ret
    ; FORMULA:
    ;     seed += 0x9E3779B97F4A7C15
    ;     z = seed
    ;     z = (z XOR (z >> 30)) * 0xBF58476D1CE4E5B9
    ;     z = (z XOR (z >> 27)) * 0x94D049BB133111EB
    ;     return z XOR (z >> 31)


; VERIFIED (99%)
gen_rand64:
    MOV rax,[state0] ; use r12 because rax will be overwritten with rot_left
    ADD rax,[state1] ; result = state0 + state1


    MOV r11,[state0] ; cannot xor [state1] wih [state0] in one instruction
    XOR [state1],r11 ; state1 ^= state0


    ; state0 = rotl(state0, 55) ^ state1 ^ (state1 << 14)
    MOV r11,[state1]
    SHL r11,14 ; (state1 << 14)

    ; rotleft
    MOV r12,[state0] ; value to rotate
    MOV cl,55       ; lower 8 bits of 55 (rotation count)
    ROL r12,cl

    XOR r12,[state1]
    XOR r12,r10
    MOV qword [state0],r12 ; state0 = ...


    ; state1 = rotl(state1, 36)
    MOV r12,[state1] ; value to rotate
    MOV cl, 36      ; lower 8 bits of arg2 (rotation count)
    ROL r12, cl

    MOV [state1],r12
    ret ; rax has stayed persistent and is still a valid return value
    ; FORMULA:
    ;     uint64_t result = state0 + state1;       // output value

    ;     state1 ^= state0;                         // xor the two states

    ;     state0 = rotl(state0, 55) ^ state1 ^ (state1 << 14);  // rotate and mix
    ;     state1 = rotl(state1, 36);           // rotate

    ;     return result;
    ; }



err__invalid_val_arg:
    LEA rax,[invalid_val_arg_msg] ; loads the address of the first value in the char array into rax
    call _throw_runtime_error
    ret

err__bad_arg_order:
    LEA rax,[invalid_inputs_msg]
    call _throw_logic_error
    ret
