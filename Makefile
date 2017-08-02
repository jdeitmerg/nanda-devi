%.o: %.vhdl
	ghdl -a $<

alu_tb: common.o alu.o alu_tb.o
	ghdl -e $@

run: alu_tb
	./alu_tb --vcd=alu.vcd

view: run
	gtkwave alu.vcd

