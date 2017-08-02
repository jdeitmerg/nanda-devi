library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;

entity alu_tb is
    -- testbench has no ports
end alu_tb;

architecture arch of alu_tb is
    signal sim_arg0, sim_arg1 : word_t;
    signal sim_res : word_t;
    signal sim_op : alu_op_t;
begin
    dut : entity work.alu
            port map (arg0 => sim_arg0, arg1 => sim_arg1,
                      result => sim_res, op => sim_op);
    process
    begin
        sim_op <= alu_uadd;
        sim_arg0 <= word_t(resize(unsigned'(X"8"), WORDWIDTH));
        sim_arg1 <= word_t(resize(unsigned'(X"3"), WORDWIDTH));
        wait for 1 ns;
        sim_arg1 <= word_t(resize(unsigned'(X"7"), WORDWIDTH));
        sim_op <= alu_or;
        wait for 1 ns;
        wait;
        
    end process;
end arch;
