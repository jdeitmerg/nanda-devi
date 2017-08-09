# About

This is a simple CPU which was written to learn VHDL. The CPU is
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
  * A flags register (flags) which contains the carry, zero and
   negative flag. It is update automatically by the ALU, but can
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
signals inside the CPU dumped for inspection with gtkwave.

Simply run

```
make view
```

to have a look at the signals.

## Modifying the code

You can play around with the components of the CPU, please have a look
at the .vhdl files in the *hardware_desc* folder. Just run

```
make view
```

again to rebuild the changed files and inspect the altered signals.

## ToDo

* Create image representation of architecture for this README.
* Memory mapping of ROM contents would be nice for initializing data
  segments.

