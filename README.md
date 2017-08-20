# Nanda Devi

Nanda Devi is a simple CPU which was written to learn VHDL. The CPU is
functional in simulation, however it is not yet completely tested.

The structure of the CPU is not designed to be efficient or nice to
use (i.e. write assembly for), but to be as simple as possible.

* It is a 32-bit architecture. Even the instructions have a fixed size of
  32 bits.
* There are 19 registers:
  * 16 general purpose ones (r0 ... r15).
  * A program counter (pc) which is updated based on the instruction
    type. It can also be read and written like all other registers.
  * A stack pointer (sp) which has no special functionality, you have
    to do all pushing and poping "manually".
  * A flags register (flags) which contains the carry, zero, negative
    and overflow flags. It is updated automatically by the ALU, but can
    also be read and written.
* Clocking is very simple: There is a global clock, the instruction
  at the program counter address shall be provided at the falling
  edge, it is executed on the rising edge.
* Memory shall be written on the rising clock edge and provided
  for reading asynchronously (probably bad for using RAM blocks on
  real FPGAs).
* The instruction memory is connected on a separate bus, we're talking
  Harvard's architecture. It is read-only (on the falling clock edge).
* The CPU consists of two external busses (memory and code), internal
  busses and **five components**:
  * The **register file** contains the 19 registers and offers several
   read and write ports to these.
  * The **arithmetic logical unit (ALU)** performs operations with
   one or two operands and generates one result. It also clears/sets the
   flags in the flags register.
  * The **instruction decoder** makes sure the correct signals are applied
   to the correct busses.
  * The **flow controller** increments the pc by 4 on normal instructions.
   On special skip instructions, it skips 2 instructions based on the
   flags in the flags register.
  * The **data bus demultiplexer** selects what data is applied to the
   register file write and memory write busses.

![CPU architecture](https://github.com/mowfask/nanda-devi/blob/master/documentation/cpu_architecture.png)

For more information, have a look at the *documentation* folder.

## Running the simulation

The CPU can be simulated using [ghdl](http://ghdl.free.fr/) which is
available for most Linux distributions. If you have make installed,
just run

```
make simulate
```

in the *hardware_desc* folder. The CPU will be build and it'll start
executing instructions from the ROM.hex file.
During simulation, the file cpu.vcd is created. It contains most of the
signals inside the CPU dumped for inspection with
[gtkwave](http://gtkwave.sourceforge.net/).

Simply run

```
make view
```

to have a look at the signals.

## Modifying the code

You can play with the code at two levels: Change the code running on the
CPU or change the CPU itself. To program the CPU in assembler, have a look
at the *assembler/example.asm* file. Run

```
assembler/as.py assembler/example.asm hardware_desc/ROM.hex
```

to assemble your code and place it where the simulator will find it.

You can also modify the .vhdl files in *hardware_desc/*.

In both cases, running one of

```
make simulate
make view
```

in *hardware_desc* rebuilds the CPU and runs the (new) ROM.hex file. The
latter opens up gtkwave again.

There is also

```
make clean
```

available if you want to remove all build files in order to rebuild
everything from scratch.

## ToDo

* Add conditional branching based on the combination of overflow
  and carry.
* Memory mapping of ROM contents would be nice for initializing data
  segments.

# License

Nanda Devi is released under the MIT License, which grants you lots of
permissions. Have a look at the *LICENSE* file for more information.

