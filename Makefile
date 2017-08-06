%.o: %.vhdl
	ghdl -a --std=08 $<

cpu_tb: common.o alu.o regfile.o instr_decoder.o flow_cntrl.o cpu.o cpu_tb.o
	ghdl -e --std=08 $@

cpu.vcd: cpu_tb ROM.hex
	./cpu_tb --vcd=$@

view: cpu.vcd 
	gtkwave cpu.vcd

clean:
	rm -rf *.o *.vcd work-obj93.cf cpu_tb

all: cpu.vcd

