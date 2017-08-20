; This file is part of the Nanda Devi project.
; Nanda Devi is a simple CPU architecture which emerged from learning
; VHDL.
;
; Copyright (c) 2017 Jonas Deitmerg
;
; For licensing information, please refer to the LICENSE file.

; ABI used by all functions in this example:
; r0, r1, r2 are used for the first three arguments, everything else
; is passed on the stack.
; The result is returned in r0. If it's bigger than 4 bytes, it is
; extended into r1, r2 and afterwards the stack.
; Functions may set r0, r1 and r2 to any value if they are not used as
; return variables.
; r14 and r15 may be changed by any function, don't rely on it being
; constant.
; All other general purpose register (r3-r13) are callee-saved, you
; may rely on them not chaning during function calls.

; set up stack pointer
ldi sp, 0x1000 ; 4*1024

ldi r14, 0x1000000
ldi r15, 4
add r14, r14, r15 ; Address of Debug 0 in r14
add r13, r14, r15 ; Address of Debug 1 in r13

; ### First examle: Print 32 bit hex value ###
; set r0 to testvalue 0x12345678
ldi r0, 0x00005678
ldi r1, 0x12340000
or r0, r0, r1

; call print_hex_nl
    ; push pc of instruction after jump
    ldi r15, 4
    sub sp, sp, r15
    ldi r15, 12
    add r15, r15, pc
    stm sp, r15
    ; actual jump
    ldi pc, @print_hex_nl

; ### Second example: Divide integer numbers ###
; Divide 27 by 6, print quotient and remainder.
ldi r0, 27
ldi r1, 6

; call div_unsigned
    ; push pc of instruction after jump
    ldi r15, 4
    sub sp, sp, r15
    ldi r15, 12
    add r15, r15, pc
    stm sp, r15
    ; actual jump
    ldi pc, @div_unsigned

; Save remainder for printing it later, quotient stays in r0 and is
; printed first.
mv r3, r1

; call print_hex_nl
    ; push pc of instruction after jump
    ldi r15, 4
    sub sp, sp, r15
    ldi r15, 12
    add r15, r15, pc
    stm sp, r15
    ; actual jump
    ldi pc, @print_hex_nl

mv r0, r3 ; Remainder of division
; call print_hex_nl
    ; push pc of instruction after jump
    ldi r15, 4
    sub sp, sp, r15
    ldi r15, 12
    add r15, r15, pc
    stm sp, r15
    ; actual jump
    ldi pc, @print_hex_nl

mv pc, pc ; hang forever - ###### END OF SIMULATION ######


@div_unsigned:
; (unsigned) divide p by q. Returns quotient and remainder.
; Register usage:
;  r0 : p (dividend) as input, res (quotient) as output
;  r1 : q (divisor) as input, r (remainder) as output
;  r3 : p (dividend) during calculation
;  r4 : q (dividor) during calculation
;  r5 : r (remainder) during calculation
;  r6 : res (quotient) during calculation
;  r7 : 1 (constant)
;  r8 : leading zeros of p, then shift (the current digit of the result)
;  r9 : leading zeros of q, then q << shift
;  r10 : q << 1

    ; first off: Save registers used in this function (see ABI)
    ldi r15, 4
    sub sp, sp, r15
    stm sp, r3
    sub sp, sp, r15
    stm sp, r4
    sub sp, sp, r15
    stm sp, r5
    sub sp, sp, r15
    stm sp, r6
    sub sp, sp, r15
    stm sp, r7
    sub sp, sp, r15
    stm sp, r8
    sub sp, sp, r15
    stm sp, r9
    sub sp, sp, r15
    stm sp, r10


    mv r3, r0 ; r3 = p
    mv r4, r1 ; r4 = q
    ldi r7, 1 ; constant

    ; First step: Find "distance" between leading zeros of p and q
    ; call leading_zeros (with p as argument)
        ; push pc of instruction after jump
        ldi r15, 4
        sub sp, sp, r15
        ldi r15, 12
        add r15, r15, pc
        stm sp, r15
        ; actual jump
        ldi pc, @leading_zeros

    mv r8, r0 ; number of leading zeros of p
    mv r0, r4
    ; call leading_zeros (with q as argument)
        ; push pc of instruction after jump
        ldi r15, 4
        sub sp, sp, r15
        ldi r15, 12
        add r15, r15, pc
        stm sp, r15
        ; actual jump
        ldi pc, @leading_zeros

    ; r0 now contains leading zeros of q
    mv r9, r0
    ; No (sub-)functions will be called from this point onwards.
    ; That means we can use r0 to r2 without worries.

    ; Initialize results in case q > p:
    ldi r0, 0 ; quotient = 0
    mv r1, r3 ; and remainder = p
    sub r8, r9, r8 ; initial shift = leading_zeros(q)-leading_zeros(p)
    snc
        ldi pc, @div_unsigned_done
        mv r0, r0
    @div_unsigned_loop:
        stm r12, r8 ; Print shift to debug 0
        ;stm r13, r1 ; And remainder to debug 1
        sll r9, r4, r8; q << shift
        sll r10, r7, r8 ; 1 << shift
        sub drop, r1, r9; r - (q << shift)
        sns
            ; r >= q << shift
            ; Add 1 << shift to result
            add r0, r0, r10
            ; And substract q << shift from remainder
            sub r1, r1, r9
        ;stm r13, r1 ; print remainder to debug 1
        ; In case the result was negative, q << shift
        ; doesn't fit into r.
        sub r8, r8, r7 ; Next shift: One bit further to the right
        sns
            ldi pc, @div_unsigned_loop
            mv r0, r0
    @div_unsigned_done:

        ; Result is already in the correct registers. Restore saved registers
        ldi r15, 4
        ldm r10, sp
        add sp, sp, r15
        ldm r9, sp
        add sp, sp, r15
        ldm r8, sp
        add sp, sp, r15
        ldm r7, sp
        add sp, sp, r15
        ldm r6, sp
        add sp, sp, r15
        ldm r5, sp
        add sp, sp, r15
        ldm r4, sp
        add sp, sp, r15
        ldm r3, sp
        add sp, sp, r15

        ; Return to caller
            ; pop pc
            ldm r14, sp
            ldi r15, 4
            add sp, sp, r15
            ; jump back
            mv pc, r14

@leading_zeros:
; return leading zeros of r0 in r0
    ldi r1, 0
    ldi r15, 1 ; constant 1
    @leading_zeros_loop:
        tst r0 ; if negative flag is set now, there are no more zeros
        snc
            ldi pc, @leading_zeros_done
            mv r0, r0
        sll r0, r0, r15
        add r1, r1, r15
        ldi pc, @leading_zeros_loop
    @leading_zeros_done:
    ; Move result to r0
    mv r0, r1
    ; Return to caller
        ; pop pc
        ldm r14, sp
        ldi r15, 4
        add sp, sp, r15
        ; jump back
        mv pc, r14

@print_hex:
; prints contents of r0 to stout as 0-padded 32-bit hex value

    ; Save used registers
    ldi r15, 4
    sub sp, sp, r15
    stm sp, r3
    sub sp, sp, r15
    stm sp, r4
    sub sp, sp, r15
    stm sp, r5
    sub sp, sp, r15
    stm sp, r6
    sub sp, sp, r15
    stm sp, r7
    sub sp, sp, r15
    stm sp, r8


    ldi r1, 0x01000000 ; Address of std output
    ldi r3, 28 ; shift of first hexchar
    ldi r4, 0xf ; mask for single hexval
    ldi r5, 4 ; number of bits per hexchar
    ldi r7, 10
    ldi r8, 9
    @print_hex_loop:
        ;stm r9, r3
        slr r2, r0, r3 ; shift input right by r3
        and r2, r2, r4 ; mask out everything but current hexval
        ldi r6, 0x30 ; '0' as a default base value
        ; Two cases: 0 <= r2 <= 9 and a <= r2 <= f
        ; drop is a special register that drops anything written to it
        ; if the result of this is positive, we're in the first case
        sub drop, r8, r2
        snc ; skip if positive
            ldi r6, 0x57 ; 'a'-0xa as base value if in second case
            mv r0, r0 ; nop as skip always skips two instructions
        add r2, r2, r6
        stm r1, r2 ; write resulting hexchar to stdout
        sub r3, r3, r5
        ; leave loop as soon as shift (r3) goes negative
        sns
            ldi pc, @print_hex_loop
            mv r0, r0

    ; Restore used registers
    ldi r15, 4
    ldm r8, sp
    add sp, sp, r15
    ldm r7, sp
    add sp, sp, r15
    ldm r6, sp
    add sp, sp, r15
    ldm r5, sp
    add sp, sp, r15
    ldm r4, sp
    add sp, sp, r15
    ldm r3, sp
    add sp, sp, r15

    ; Return to caller
        ; pop pc
        ldm r14, sp
        ldi r15, 4
        add sp, sp, r15
        ; jump back
        mv pc, r14

@print_hex_nl:
; prints contents of r0 to stout as 0-padded 32-bit hex value
; and appends a newline

; call print_hex:
    ; push pc of instruction after return
    ldi r15, 4
    sub sp, sp, r15
    ldi r15, 12
    add r15, r15, pc
    stm sp, r15
    ; actual jump
    ldi pc, @print_hex

; print newline
ldi r1, 0x01000000 ; Address of std output
ldi r2, 0x0a ; '\n'
stm r1, r2
; Return to caller
    ; pop pc
    ldm r14, sp
    ldi r15, 4
    add sp, sp, r15
    ; jump back
    mv pc, r14

