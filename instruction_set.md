# Instruction set

## General considerations

All instructions are designed to fit into 32 bits, we're talking about a
fixed size instruction set.

Addressing a register as an argument for an instruction takes 5 bits as
there are more than 16 registers (19 to be exact).

## Constants / load immediate

The current (simple!) architecture doesn't allow using a constant encoded
into the instruction as an argument to instructions. As constant values
still have to find their way into the registers, there is one exception
to this rule: The ldi (load immediate) instruction. Obviously, it cannot
provide a 32 bit value in a 32 bit instruction. To allow some flexiblity,
the instruction shall provide a **signed 17-bit value**, as well as 4-bit
shift which determines where in the 32-bit destination the 17 bits shall
be placed. The shifted 17-bit value shall automatically be sign-extended
to the full 32 bits. This concept allows the placement of an unsigned
16-bit value anywhere in the 32 bits. In the extreme case of shift = 15,
a 17-bit value can be placed in the upper 17 bits of the word, as the
sign-extension doesn't have any effect (see below). All non-defined
values are set to 0 if they aren't set to 1 by the sign-extension.

Bits of destination word:  31 30 29 28 27 ... 16 15  14  13 ...  1   0
Bits of constant / values: 16 15 14 13 12 ...  1  0 '0' '0' ... '0' '0'

For signed values, -1 through -65536 as well as some odd shifted values
are possible.

Making a long story short: The *laod immediate* instruction uses 21 bits
for the constant and 5 bits for the destination = **26 bits**.

## ALU instructions

To keep the decoder simple, the instruction word should include the ALU
operation code (op). Being generous, let's allocate 5 bits for the ALU op
as well as allow arbitrary source and destination registers. Allocate
two sources and one destination register for all ALU operations, even
if that's not strictly necessary. -> 5 bits + 3 * 5 bits = **20 bits**
for all ALU operations.

## Memory and copy instructions

Yep, we need these as well:

Mem to reg and reg to mem: One register specifies address, the other one
the value. So 1 bit + 2 * 5 bits = 11 bits for mem to reg and reg to mem
transfers.

As it would be crazy to handle register to register transfers *through*
the ALU, we shall allocate another instruction just for that.
3 * 5 bits for source, value and destination = 15 bits.

We'll waste that 4 bit difference and allocate **17 bits** for all
memory + copy instructions

## (Conditional) jumps

Turns out jumping around in the program memory is rather important. Jumping
to an address stored in any register can be done by copying it to the pc
register. Program counter arithmetic is also possible using the ALU.

Conditional jumps are a different story. You know what, we'll keep this
really simple. We'll only allow skipping based on the zero, negative and
carry flag. An we'll skip not one but two instructions as you need two
instructions to load an offset and add it to the program counter.

To offer some more flexibility, allow skipping if flags are *not* set
as well.

With only 6 possible instructions we'd need only 3 bits. We'll allocate
**9 bits** instead to make the instruction decoder simpler.

## Ideas for improvement

* As there is still adressing space for more registers, we could add a
  pseudo-register which gets its value from the instruction decoder.
  Wouldn't even have to be saved in a flip-flop. This would enable
  using constants as arguments and therefore one cycle jumps would be
  possible.

# Actual instruction structure

We got only 4 different groups of instructions and the biggest of them
needs 26 bits. 5 bits shall be allocated for the instruction group,
that leaves another 28 instruction groups to be implemented with a
maximum size of 27 bits.

By numbering the groups as done below, only one 8th of the available
instruction space is used.

Source registers (src1, src0) can be any value if not applicable. If no
register is to be written, dest has to be set to 19.

| Group \ Bits     | 31 30 29 28 27 | 26 25 ... 16 15 | 14 13  ...  1  0 |
|------------------|----------------|-----------------|------------------|
|                  | Instr. group   | Group specific  | src1, src0, dest |
|
| Load Immediate   |  0  0  0  0  0 |                 |                  |
| ALU instructions |  0  0  0  0  1 |                 |                  |
| Memory and copy  |  0  0  0  1  0 |                 |                  |
| Cond. jumps      |  0  0  0  1  1 |                 |                  |

## Load immediate

| 31 ... 27 | 26 | 25  ...  22 | 21   ...   5 | 4 ... 0 |
|-----------|----|-------------|--------------|---------|
|  0  0   0 |  0 | 4 bit shift | 17 bit value | dest    |

## ALU instructions

Only these ALU instructions update the flags register.

|      | 31 ... 27 | 26 ... 20 | 19 18 17 16 15 | 14...10| 9...5 | 4...0 |
|------|-----------|-----------|----------------|--------|-------|-------|
|      |  0  0   1 |  0  0   0 | ALU op-code    |  src1  |  src0 | dest  |
|
| add  |  0  0   1 |  0  0   0 |  0  0  0  0  0 |  src1  |  src0 | dest  |
| sub  |  0  0   1 |  0  0   0 |  0  0  0  0  1 |  src1  |  src0 | dest  |
| addc |  0  0   1 |  0  0   0 |  0  0  0  1  0 |  src1  |  src0 | dest  |
| subc |  0  0   1 |  0  0   0 |  0  0  0  1  1 |  src1  |  src0 | dest  |
| or   |  0  0   1 |  0  0   0 |  0  0  1  0  0 |  src1  |  src0 | dest  |
| xor  |  0  0   1 |  0  0   0 |  0  0  1  0  1 |  src1  |  src0 | dest  |
| and  |  0  0   1 |  0  0   0 |  0  0  1  1  0 |  src1  |  src0 | dest  |
| not  |  0  0   1 |  0  0   0 |  0  0  1  1  1 | 00000  |  src  | dest  |
| sll  |  0  0   1 |  0  0   0 |  0  1  0  0  0 |  src1  |  src0 | dest  |
| slr  |  0  0   1 |  0  0   0 |  0  1  0  0  1 |  src1  |  src0 | dest  |
| tst  |  0  0   1 |  0  0   0 |  0  1  0  1  0 | 00000  |  src  | 10011 |

# Memory and copy instructions

* mv: Copy from src to dest register.
* ldm: Load value pointed to by src register to dest register.
* stm: Store src register at memory location specified by dest register.

|     | 31 ... 28 27 | 26 ... 17 | 16 15 | 14 ... 10 | 9 ... 5 | 4 ... 0|
|-----|--------------|-----------|-------|-----------|---------|--------|
|     |  0  0   1  0 |  0  0   0 |       |           |         |        |
|
| mv  |  0  0   1  0 |  0  0   0 |  0  0 |  0 0 0 0  |   src   |  dest  |
| ldm |  0  0   1  0 |  0  0   0 |  0  1 |   [src]   | 0 0 0 0 |  dest  |
| stm |  0  0   1  0 |  0  0   0 |  1  0 |  [dest]   |   src   |  10011 |


# Conditions jumps/skips

* Mnemonic is always **s**kip **c/z/n**-flag **s/c** set/cleared

|     | 31 ... 28 27 | 26 ... 9 | 8 7 6 5 | 4 3 2 1 0 |
|-----|--------------|----------|---------|-----------|
|     |  0  0   1  1 |  0  0  0 |         | 1 0 0 1 1 |
|
| scs |  0  0   1  1 |  0  0  0 | 0 0 0 1 | 1 0 0 1 1 |
| scc |  0  0   1  1 |  0  0  0 | 1 0 0 1 | 1 0 0 1 1 |
| szs |  0  0   1  1 |  0  0  0 | 0 0 1 0 | 1 0 0 1 1 |
| szc |  0  0   1  1 |  0  0  0 | 1 0 1 0 | 1 0 0 1 1 |
| sns |  0  0   1  1 |  0  0  0 | 0 1 0 0 | 1 0 0 1 1 |
| snc |  0  0   1  1 |  0  0  0 | 1 1 0 0 | 1 0 0 1 1 |

