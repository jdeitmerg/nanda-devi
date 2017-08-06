%.o: %.vhdl
	ghdl -a $<

cpu_tb: common.o alu.o regfile.o instr_decoder.o flow_cntrl.o cpu.o
	#ghdl -e $@

cpu.vcd: cpu_tb
	#./cpu_tb --vcd=$@

view: cpu.vcd 
	#gtkwave cpu.vcd

clean:
	rm -rf *.o *.vcd work-obj93.cf cpu_tb

all: cpu.vcd

