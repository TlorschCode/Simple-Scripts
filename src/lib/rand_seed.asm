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
global gen_seed
global randint
global gen_seed_biasless
global randint_biasless


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
        RDSEED rdx ; MULX uses rdx instead of rax
        MULX rbx,rax,rdx ; low 64 bits go into rbx, high 64 bits go into rax (since multiplying two 64 bit unsigned ints together could result in 128 bits needed of total storage)
        ; this results in basically no bias (1 / (2^64) of bias, or ~0.00000000000000000005...)
        ret
        
gen_seed_biasless:
    CMP arg1,arg2
    JA .call_bad_arg_order
    JE bseed__rangeless_so_RET_min
    JMP seed__check_bits
    .call_bad_arg_order:
        call err__bad_arg_order
        JMP end_func__seed
    bseed__no_range_so_ret_min:
        MOV rax,[arg1]
        ret
    
    
    seed__gen_biasless16:
        RDSEED rdx ; MULX uses rdx instead of rax
        CMP
        MULX rbx,rax,rdx ; low 64 bits go into rbx, high 64 bits go into rax (since multiplying two 64 bit unsigned ints together could result in 128 bits needed of total storage)
        ; this results in basically no bias (1 / (2^64) of bias, or ~0.00000000000000000005...)
        ret

__randint:
    CMP rcx,rdx
    JA .call_bad_arg_order
    JE randint__rangeless_so_ret_min
    JMP randint__gen_num
    .call_bad_arg_order:
        call err__bad_arg_order
        JMP end_func__randint
    randint__rangeless_so_ret_min:
        MOV rax,rcx
        ret
    
    randint__gen_num:
        RDRAND rdx
        MULX rbx,rax,rdx ; low 64 bits go into rbx, high 64 bits go into rax (since multiplying two 64 bit unsigned ints together could result in 128 bits needed of total storage)
        ; this results in basically no bias (1 / (2^64) of bias, or ~0.00000000000000000005...)
        ret

; uint64_t randint(uint64_t* state0, uint64_t* state1) {
;     uint64_t s0 = *state0;
;     uint64_t s1 = *state1;

;     uint64_t result = s0 + s1;       // output value

;     s1 ^= s0;                         // xor the two states
;   // ^^^ COMPLETE ^^^

;     *state0 = rotl(s0, 55) ^ s1 ^ (s1 << 14);  // rotate and mix
;     *state1 = rotl(s1, 36);           // rotate

;     return result;
; }
randint:
    MOV r13,[state0]
    ADD r13,[state1]
    MOV r14,[state0]
    XOR r14,[state1]

    ; state0 = rotl(s0, 55) ^ s1 ^ (s1 << 14)
    MOV arg1,[state0]
    MOV arg2,55
    rot_left
    MOV r15,rax
    XOR r15,[state1]
    MOV r10,[state1]
    SHL r10,14
    XOR r15,r10
    MOV [state0],r15

    ; *state1 = rotl(s1, 36);
    MOV arg1,[state1]
    MOV arg2,36
    rot_left
    MOV [state1],rax
    MOV rax,r13
    ret


err__invalid_val_arg:
    LEA rax,[invalid_val_arg_msg] ; loads the address of the first value in the char array into rax
    call _throw_runtime_error
    ret

err__bad_arg_order:
    LEA rax,[invalid_inputs_msg]
    call _throw_logic_error
    ret
