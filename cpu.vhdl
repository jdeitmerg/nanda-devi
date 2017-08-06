library ieee;
use ieee.std_logic_1164.all;
use work.common.all;

entity cpu is

end cpu;

architecture arch of cpu is
    -- Plenty of signals between the CPU's components:
    signal clk : std_logic; -- global clock signal

    -- Data written to register or memory
    signal data_bus : word_t;
    -- For demultiplexing what is on the data bus:
    type data_sources_t is array(dsrc_t) of word_t;
    signal data_sources : data_sources_t;
    signal dsrc_selector : dsrc_t;

    signal instr_immediate : word_t;
    signal mem_addr, mem_read, mem_write : word_t;

    -- carry, zero and negative flag for flow control
    signal flags_read, flags_write : flags_t;
    signal flags_we : std_logic; -- whether or not ALU shall update flags
    signal fc_flaginv : std_logic;
    signal fc_command : flow_control_t;

    -- Signals of register file
    signal pc_read, pc_write : word_t;
    signal reg_w_sel, reg_r_sel0, reg_r_sel1 : regnum_t;

    -- Signals of the ALU
    signal arg0, arg1, alu_res : word_t;
    signal alu_op : alu_op_t;

    -- For instruction decoder:
    signal instruction : word_t;
begin
    flow_controller : entity work.flow_cntrl
        port map ( flags => flags_read,
                   flag_inv => fc_flaginv,
                   pc_current => pc_read,
                   pc_next => pc_write,
                   command => fc_command
                 );

    registers : entity work.regfile
        port map ( clk => clk,
                   write_select => reg_w_sel,
                   write_data => data_bus,
                   read_select0 => reg_r_sel0,
                   read_select1 => reg_r_sel1,
                   read_data0 => arg0,
                   read_data1 => arg1,
                   read_pc => pc_read,
                   read_flags => flags_read,
                   write_pc => pc_write,
                   write_flags => flags_write,
                   flags_we => flags_we
                 );

    alu_inst : entity work.alu
        port map ( arg0 => arg0,
                   arg1 => arg1,
                   op => alu_op,
                   result => alu_res,
                   flags_in => flags_read,
                   flags_out => flags_write
                 );

    instruction_dec : entity work.instr_decoder
        port map ( clk => clk,
                   instruction => instruction,
                   alu_op => alu_op,
                   flow_control => fc_command,
                   data_src => dsrc_selector,
                   immediate => instr_immediate,
                   reg_dest => reg_w_sel,
                   reg_src0 => reg_r_sel0,
                   reg_src1 => reg_r_sel1,
                   flags_we => flags_we
                 );

    -- Data bus demultiplexer:
    data_sources(dsrc_ALU) <= alu_res;
    data_sources(dsrc_arg0) <= arg0;
    data_sources(dsrc_immediate) <= instr_immediate;
    data_sources(dsrc_mem) <= mem_read;
    data_bus <= data_sources(dsrc_selector);

end arch;

