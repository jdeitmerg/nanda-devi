ldi r0, 0x01000000 ; Address of std output
ldi r1, 0x48 ; 'H'
stm r0, r1
ldi r1, 0x65 ; 'e'
stm r0, r1
ldi r1, 0x6c ; 'l'
stm r0, r1
ldi r1, 0x6c ; 'l'
stm r0, r1
ldi r1, 0x6f ; 'o'
stm r0, r1
ldi r1, 0x0a ; '\n'
stm r0, r1

@loop_forever:
mv pc, pc ; This "hang instruction" ends the simulation

