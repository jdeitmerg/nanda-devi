ldi r0, 5
ldi r1, -4
add r2, r1, r0
ldi r3, 0
stm r3, r2 ; Save result of addition at address 0x00

tst r0
sns ; skip following two instructions if negative flag
; is set
ldi r3, 4
mv r0, r0
stm r3, r2

mv pc, pc ; loop forever
