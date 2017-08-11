; set up stack pointer
ldi sp, 0x1000 ; 4*1024
ldi r15, 4 ; for incrementing and decrementing sp. Functions rely on r15 to be 4!

; set r0 to testvalue 0x12345678
ldi r0, 0x00005678
ldi r1, 0x12340000
or r0, r0, r1

; call print_hex_nl
    ; push pc of instruction after jump
    sub sp, sp, r15
    ldi r1, 12
    add r1, r1, pc
    stm sp, r1
    ; actual jump
    ldi pc, @print_hex_nl

; set r0 to testvalue 0
ldi r0, 0

; call print_hex_nl
    ; push pc of instruction after jump
    sub sp, sp, r15
    ldi r1, 12
    add r1, r1, pc
    stm sp, r1
    ; actual jump
    ldi pc, @print_hex_nl

mv pc, pc ; hang forever - this stops the simulation

@print_hex:
; prints contents of r0 to stout as 0-padded 32-bit hex value
    ldi r1, 0x01000000 ; Address of std output
    ldi r3, 28 ; shift of first hexchar
    ldi r4, 0xf ; mask for single hexval
    ldi r5, 4 ; number of bits per hexchar
    ldi r7, 10
    ldi r8, 9
    @print_hex_loop:
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
    ; Return to caller
        ; pop pc
        ldm r1, sp
        add sp, sp, r15
        ; jump back
        mv pc, r1

@print_hex_nl:
; prints contents of r0 to stout as 0-padded 32-bit hex value
; and appends a newline

; call print_hex:
    ; push pc of instruction after return
    sub sp, sp, r15
    ldi r1, 12
    add r1, r1, pc
    stm sp, r1
    ; actual jump
    ldi pc, @print_hex

; print newline
ldi r1, 0x01000000 ; Address of std output
ldi r2, 0x0a ; '\n'
stm r1, r2
; Return to caller
    ; pop pc
    ldm r1, sp
    add sp, sp, r15
    ; jump back
    mv pc, r1

