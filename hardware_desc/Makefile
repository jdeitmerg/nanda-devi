# This file is part of the Nanda Devi project.
# Nanda Devi is a simple CPU architecture which emerged from learning
# VHDL.
#
# Copyright (c) 2017 Jonas Deitmerg
#
# For licensing information, please refer to the LICENSE file.

WORKDIR=work
GHDL_OPTIONS= -g --std=08 --workdir=$(WORKDIR)
ANALYZE= -a $(GHDL_OPTIONS)
ELABORATE= -e $(GHDL_OPTIONS)

cpu_tb: $(WORKDIR)/cpu_tb.o
	ghdl $(ELABORATE) $@

alu_tb: $(WORKDIR)/alu_tb.o
	ghdl $(ELABORATE) $@

$(WORKDIR)/common.o: common.vhdl
	ghdl $(ANALYZE) $<

$(WORKDIR)/cpu.o: cpu.vhdl $(WORKDIR)/common.o $(WORKDIR)/alu.o $(WORKDIR)/regfile.o $(WORKDIR)/instr_decoder.o $(WORKDIR)/flow_cntrl.o
	ghdl $(ANALYZE) $<

$(WORKDIR)/cpu_tb.o: cpu_tb.vhdl $(WORKDIR)/cpu.o
	ghdl $(ANALYZE) $<

$(WORKDIR)/alu_tb.o: alu_tb.vhdl $(WORKDIR)/alu.o
	ghdl $(ANALYZE) $<

$(WORKDIR)/%.o: %.vhdl $(WORKDIR)/common.o
	ghdl $(ANALYZE) $<

run_tests: alu_tb
	./alu_tb

simulate: cpu_tb ROM.hex sigdump.conf
	./cpu_tb --read-wave-opt=sigdump.conf --vcd=cpu.vcd

cpu.vcd: simulate

view: cpu.vcd 
	gtkwave cpu.vcd

clean:
	rm -rf *.vcd cpu_tb alu_tb $(WORKDIR)/*.o $(WORKDIR)/work-obj08.cf

