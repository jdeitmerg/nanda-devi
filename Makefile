cpu_tb: cpu_tb.o
	ghdl -e --std=08 $@

common.o: common.vhdl
	ghdl -a --std=08 $<

cpu.o: cpu.vhdl common.o alu.o regfile.o instr_decoder.o flow_cntrl.o
	ghdl -a --std=08 $<

cpu_tb.o: cpu_tb.vhdl cpu.o
	ghdl -a --std=08 $<

%.o: %.vhdl common.o
	ghdl -a --std=08 $<

cpu.vcd: cpu_tb ROM.hex sigdump.conf
	./cpu_tb --read-wave-opt=sigdump.conf --vcd=$@

view: cpu.vcd 
	gtkwave cpu.vcd

clean:
	rm -rf *.o *.vcd work-obj93.cf cpu_tb

all: cpu.vcd

