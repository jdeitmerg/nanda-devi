%.o: %.vhdl
	ghdl -a $<

alu_tb: common.o alu.o alu_tb.o regfile.o cpu.o
	ghdl -e $@

run: alu_tb
	./alu_tb --vcd=alu.vcd

view: run
	gtkwave alu.vcd

clean:
	rm -rf *.o *.vcd work-obj93.cf alu_tb

all: run

